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
# the blind spot all six #172 defects shipped through.
#
# SCOPE, because the error text below reads more absolute than the check is: this
# walks ONE level. Top-level keys, plus one level under `exportarr:`, which nests
# its whole config. Nested passthroughs — `metrics.serviceMonitor.relabelings`,
# `service.rcon.externalIPs`, `exportarr.apps.<app>[].volumes` — are NOT walked and
# are the larger half of the surface (roughly 13 nested vs 10 top-level per chart,
# and 47 vs 0 for exportarr). Review still owns those. Do not read a green guard as
# "every passthrough is covered".
#
# A default of `{}`, `[]`, or a bare key with no children marks a passthrough, so
# no hand-maintained list is needed at this level. A default of `""` does not —
# credential-gated templates like `secret.yaml` stay invisible here by design.
if [[ "$name" == exportarr ]]; then parent="exportarr" indent="  "; else parent="" indent=""; fi
section() { # <file> — whole file, or just the `$parent:` block when set
  if [[ -z "$parent" ]]; then cat "$1"
  else awk -v k="$parent" '$0 ~ "^"k": *$"{f=1;next} /^[^ #]/{f=0} f' "$1"
  fi
}
# Keys whose value is empty: `{}`, `[]`, or nothing at all (a bare `key:` whose
# next line is not a child). Tolerates trailing comments, CRLF and quoted keys.
empty_keys() {
  awk -v ind="${#indent}" '
    { sub(/\r$/, "") }
    /^[[:space:]]*$/ || /^[[:space:]]*#/ { next }
    {
      pad = match($0, /[^ ]/) - 1
      # A bare key held from the previous line is empty only if this line is not
      # its child.
      if (pending != "" && pad <= ind) print pending
      pending = ""
      if (pad == ind && match($0, /^ *"?[A-Za-z0-9_.-]+"?:/)) {
        key = substr($0, RSTART, RLENGTH); gsub(/^ *"?|"?:$/, "", key)
        rest = substr($0, RSTART + RLENGTH)
        sub(/#.*$/, "", rest); gsub(/^[ \t]+|[ \t]+$/, "", rest)
        if (rest == "{}" || rest == "[]") print key
        else if (rest == "") pending = key
      }
    }
    END { if (pending != "") print pending }
  '
}
merged_overlay="$(section "$overlay"; if [[ -f "$chart_overlay" ]]; then section "$chart_overlay"; fi)"
missing=()
while read -r key; do
  [[ -n "$key" ]] || continue
  # Literal match: chart keys may contain `.`, which is a regex metacharacter.
  esc="$(printf '%s' "$key" | sed -E 's/[][\.^$*+?(){}|\\\/]/\\&/g')"
  # A hit only counts when it carries a payload — `key: {}` in the overlay is the
  # same non-coverage as no key at all, and is what the error below forbids.
  if grep -qE -- "^${indent}${esc}:" <<<"$merged_overlay" \
     && ! grep -qE -- "^${indent}${esc}: *(\{\}|\[\]) *$" <<<"$merged_overlay"; then
    continue
  fi
  missing+=("$key")
done < <(section "$chart/values.yaml" | empty_keys | sort -u)
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: $name declares passthrough(s) the kubeconform overlay never populates:" >&2
  printf '         %s\n' "${missing[@]}" >&2
  echo "       They render empty, so their toYaml/nindent path executes in no pass." >&2
  echo "       Add a real payload (>=2 entries) to $(basename "$overlay"), or to" >&2
  echo "       scripts/ci/kubeconform-values/$name.yaml if the shape is chart-specific." >&2
  echo "       An empty \`key: {}\` in the overlay does NOT count as covered." >&2
  exit 1
fi

# Pass 2 — every off-by-default feature forced on. Without it the CRD kinds and a
# dozen core-kind templates (ServiceAccount, Ingress, …) render in no pass at all.
crd_render="$(render "${overlay_args[@]}")"

# Green on an empty document is the failure mode this gate exists to catch, and
# kubeconform reports `Valid: 0, Invalid: 0, Errors: 0` for no input at all. Pass 1
# can legitimately be empty — exportarr renders nothing on defaults, since every app
# is disabled — but pass 2 forces every feature on, so an empty render there means
# the overlay missed the chart entirely.
if ! grep -q '^kind: ' <<<"$crd_render"; then
  echo "ERROR: $name rendered no resources with the overlay applied." >&2
  echo "       kubeconform reports Valid: 0 / Errors: 0 on an empty document, so this" >&2
  echo "       would otherwise pass while validating nothing." >&2
  exit 1
fi

# A renamed values key would make pass 2 render a subset and still report
# `Skipped: 0`, so check the CRD templates on disk against what actually came out.
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
