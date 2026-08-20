#!/usr/bin/env bash
# Validate markdown links, anchors, and this repo's ArtifactHub link policy.
# Usage: scripts/ci/check-links.sh [--online <report.md>]
# Mirrors `task check-links`. Needs lychee on PATH (see CONTRIBUTING).
#
# Default mode is the PR gate. `--online` is the weekly link-rot run driven by
# .github/workflows/link-rot.yml: same invocation minus --offline, so external
# URLs are actually fetched, writing a markdown report for the issue it files.
# It lives here rather than inline in the workflow so the remap - which has to be
# built at runtime, because a file:// remap target must be an absolute path and
# so cannot live in a lychee.toml - exists in exactly one place.
#
# Two passes, because no single off-the-shelf tool covers both halves.
#
# Pass 1 - lychee, offline. Resolves every link that can be resolved from the
# tree: relative paths, in-page `#anchor` fragments, and - via --remap - this
# repo's own `blob/main/` URLs, rewritten to local files so their paths AND
# fragments are checked on disk instead of over the network. That matters here
# because ArtifactHub renders only the packaged README and drops relative links,
# so every cross-file chart link is written as an absolute URL and would
# otherwise go unchecked. --offline skips genuinely external links: this gate
# has no network budget and link rot is not what it is guarding.
#
# Pass 2 - the policy lychee cannot express. A relative link under charts/
# resolves fine on disk, so lychee passes it green, but ArtifactHub's renderer
# tests `/^https?:/` and falls through to `href.startsWith('#')`, discarding
# anything else: the text renders as unclickable prose and a relative image
# renders as nothing at all. Invisible on GitHub, where the file is local.
#
# Both failure modes are invisible in a diff too. PR #186 shipped three separate
# classes of them and every one was caught by hand.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

if ! command -v lychee >/dev/null; then
  echo "lychee not found on PATH - see the tool table in CONTRIBUTING.md" >&2
  exit 1
fi

# `\$1` is lychee's own capture-group reference, not a shell positional.
remap="https://github.com/homeylab/helm-charts/blob/main/(.*) file://$root/\$1"
inputs=('./charts/**/*.md' './*.md')

if [ "${1:-}" = "--online" ]; then
  # Rot only. The relative-link policy is already enforced on every PR, and its
  # findings would not appear in the markdown report the cron files as an issue.
  exec lychee --no-progress --include-fragments=anchor-only --max-concurrency 8 \
    --format markdown --output "${2:?usage: check-links.sh --online <report.md>}" \
    --remap "$remap" "${inputs[@]}"
fi

# Both passes always run: a broken anchor must not hide a policy violation, the
# same reason ci-tooling.yml marks its docs steps `if: !cancelled()`.
fail=0

lychee --offline --no-progress --include-fragments=anchor-only \
  --remap "$remap" "${inputs[@]}" || fail=1

python3 scripts/ci/check-relative-links.py || fail=1

exit "$fail"
