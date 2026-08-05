#!/usr/bin/env bash
# Render a chart and validate the manifests against Kubernetes + CRD schemas.
# Usage: scripts/ci/kubeconform.sh <chart-dir>   (chart-dir e.g. charts/pihole-exporter)
# Mirrors `task kubeconform`. Invoked per-chart by ct via ct.yaml additional-commands.
set -euo pipefail

chart="${1:?usage: kubeconform.sh <chart-dir>}"
name="$(basename "$chart")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
k8s="${K8S_VERSION:-1.30.0}"
cache="$root/.cache/kubeconform"

# CRD schemas, via kubeconform's own documented catalog invocation. This and the
# `default` location are both remote and unpinned — the gate has always needed
# the network. Schemas cache with no expiry; `rm -rf .cache/` forces a refetch.
catalog='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

render() { helm template "$name" "$chart" --kube-version "$k8s" "$@"; }

# No -ignore-missing-schemas: a 404 from a renamed catalog path or a typo'd kind
# would read as a pass. (Outages were never silent — they error out either way.)
validate() {
  mkdir -p "$cache"
  kubeconform -strict -summary -kubernetes-version "$k8s" -cache "$cache" \
    -schema-location default -schema-location "$catalog"
}

# Pass 1 — default values, what users actually install.
render | validate

# The overlay is fleet-wide, so it only carries keys whose name AND shape are the
# same everywhere. Anything chart-specific — v-rising's persistence/service
# nesting, nut's webconfig_file, exportarr's whole nested subtree — lives in a
# per-chart file, applied on top when it exists. Same guarded-pickup shape
# prometheus-community uses for its per-chart `ci/lint.sh`.
overlay="$root/scripts/ci/kubeconform-values.yaml"
chart_overlay="$root/scripts/ci/kubeconform-values/$name.yaml"
overlay_args=(--values "$overlay")
if [[ -f "$chart_overlay" ]]; then overlay_args+=(--values "$chart_overlay"); fi

# Coverage guard. A passthrough the overlay never populates renders nothing, so
# its `toYaml | nindent` path is executed by no pass and validated by nothing —
# the blind spot all six #172 defects shipped through. A chart default of `{}` or
# `[]` marks exactly those keys, so this needs no hand-maintained list: it stays
# correct as charts gain values. Top level only, plus one level under
# `exportarr:`, which nests its whole config; deeper passthroughs
# (metrics.serviceMonitor.*) are not walked and still rely on review.
if [[ "$name" == exportarr ]]; then parent="exportarr" indent="  "; else parent="" indent=""; fi
section() { # <file> — whole file, or just the `$parent:` block when set
  if [[ -z "$parent" ]]; then cat "$1"
  else awk -v k="$parent:" '$0==k{f=1;next} /^[a-zA-Z0-9_-]+:/{f=0} f' "$1"
  fi
}
merged_overlay="$(section "$overlay"; if [[ -f "$chart_overlay" ]]; then section "$chart_overlay"; fi)"
missing=()
while read -r key; do
  [[ -n "$key" ]] || continue
  grep -qE "^${indent}${key}:" <<<"$merged_overlay" || missing+=("$key")
done < <(section "$chart/values.yaml" \
  | grep -E "^${indent}[a-zA-Z0-9_-]+: *(\{\}|\[\]) *$" \
  | sed -E "s/^${indent}([a-zA-Z0-9_-]+):.*/\1/")
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: $name declares passthrough(s) the kubeconform overlay never sets:" >&2
  printf '         %s\n' "${missing[@]}" >&2
  echo "       They default to empty, so their toYaml/nindent path renders in no pass." >&2
  echo "       Add a real payload (>=2 entries) to $(basename "$overlay"), or to" >&2
  echo "       scripts/ci/kubeconform-values/$name.yaml if the shape is chart-specific." >&2
  exit 1
fi

# Pass 2 — every off-by-default feature forced on. Without it the CRD kinds and a
# dozen core-kind templates (ServiceAccount, Ingress, …) render in no pass at all.
crd_render="$(render "${overlay_args[@]}")"

# A renamed values key would make pass 2 render nothing and still report
# `Skipped: 0`. Green on an empty document is the failure this gate exists to
# catch, so check the CRD templates on disk against what actually came out.
# Kinds are read from the templates, so only the filenames are listed here.
for f in "$chart"/templates/{servicemonitor,prometheusrule,httproute}.yaml; do
  [[ -f "$f" ]] || continue
  kind="$(awk '/^kind: /{print $2; exit}' "$f")"
  grep -q "^kind: ${kind}$" <<<"$crd_render" && continue
  echo "ERROR: $name ships $(basename "$f") but the overlay rendered no ${kind}." >&2
  echo "       Check its toggle in scripts/ci/kubeconform-values.yaml, or in" >&2
  echo "       scripts/ci/kubeconform-values/$name.yaml." >&2
  exit 1
done

printf '%s\n' "$crd_render" | validate
