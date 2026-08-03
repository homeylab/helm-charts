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

# Pass 2 — every off-by-default feature forced on. Without it the CRD kinds and a
# dozen core-kind templates (ServiceAccount, Ingress, …) render in no pass at all.
crd_render="$(render --values "$root/scripts/ci/kubeconform-values.yaml")"

# A renamed values key would make pass 2 render nothing and still report
# `Skipped: 0`. Green on an empty document is the failure this gate exists to
# catch, so check the CRD templates on disk against what actually came out.
# Kinds are read from the templates, so only the filenames are listed here.
for f in "$chart"/templates/{servicemonitor,prometheusrule,httproute}.yaml; do
  [[ -f "$f" ]] || continue
  kind="$(awk '/^kind: /{print $2; exit}' "$f")"
  grep -q "^kind: ${kind}$" <<<"$crd_render" && continue
  echo "ERROR: $name ships $(basename "$f") but the overlay rendered no ${kind}." >&2
  echo "       Check its toggle in scripts/ci/kubeconform-values.yaml." >&2
  exit 1
done

printf '%s\n' "$crd_render" | validate
