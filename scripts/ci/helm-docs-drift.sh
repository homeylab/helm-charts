#!/usr/bin/env bash
# Fail if any generated README.md differs from what helm-docs would produce now.
# Usage: scripts/ci/helm-docs-drift.sh   (walks every chart)
# Mirrors `task docs-drift`.
#
# `README.md` is generated from `README.md.gotmpl` plus the `# --` comments in
# `values.yaml`, and it is the file that ships in the .tgz and renders on
# ArtifactHub. Regeneration is manual (`task docs`), so a forgotten run leaves the
# shipped README describing values that no longer exist, with nothing to catch it:
# ct only reports "chart changed", never "README stale".
#
# Regenerates into a throwaway copy rather than the working tree, so running this
# locally never leaves you with edits you did not ask for.
#
# Only charts that HAVE a README.md.gotmpl are touched, one at a time. Never run
# helm-docs with --chart-search-root=charts: nut-exporter's README is hand-written
# and has no .gotmpl, so a fleet-wide invocation overwrites it with the helm-docs
# default template.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp -r "$root/charts" "$work/charts"

fail=0
for chart in "$work"/charts/*/; do
  name="$(basename "$chart")"
  [ -f "$chart/README.md.gotmpl" ] || continue

  helm-docs --chart-search-root="$chart" --log-level warning >/dev/null

  if ! diff -u "$root/charts/$name/README.md" "$chart/README.md" \
       --label "charts/$name/README.md (committed)" \
       --label "charts/$name/README.md (regenerated)"; then
    echo "::error file=charts/${name}/README.md::README.md is stale — run 'task docs APP=${name}'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "all generated READMEs are up to date"
fi
exit "$fail"
