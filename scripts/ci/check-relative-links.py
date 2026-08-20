#!/usr/bin/env python3
"""Reject relative markdown links in the files that ship to ArtifactHub.

Usage: scripts/ci/check-relative-links.py   (walks tracked .md under charts/)
Run from scripts/ci/check-links.sh, alongside the lychee pass that resolves
everything else. See that script's header for why this half is hand-written:
lychee resolves a relative link on disk, finds the file, and passes it.

ArtifactHub renders only the packaged chart README. Its renderer tests
`/^https?:/` for links and falls through to `href.startsWith('#')` for the rest,
discarding any other href - the link text survives as unclickable prose, and a
relative image (`/^https?:/.test(src) ? <img/> : null`) renders as nothing.
So inside charts/, a cross-file link must be the full
https://github.com/homeylab/helm-charts/blob/main/… URL.

Only charts/ is checked. README.md and CONTRIBUTING.md never leave GitHub, where
relative links are the correct form.
"""

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FENCE = re.compile(r"^```.*?^```", re.S | re.M)
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)\)")
ABSOLUTE = re.compile(r"^(?:[a-z][a-z0-9+.-]*:|//|#)")


def main():
    listed = subprocess.run(
        ["git", "-C", str(REPO), "ls-files", "-z", "charts/*.md", "charts/**/*.md"],
        capture_output=True, text=True, check=True,
    ).stdout
    paths = sorted(REPO / p for p in listed.split("\0") if p)

    bad = []
    for path in paths:
        body = FENCE.sub("", path.read_text())
        for href in LINK.findall(body):
            if not ABSOLUTE.match(href):
                bad.append((path.relative_to(REPO), href))

    for rel, href in bad:
        print(
            f"error: {rel}: relative link `{href}` - ArtifactHub drops these silently; "
            f"use the full https://github.com/homeylab/helm-charts/blob/main/… URL",
            file=sys.stderr,
        )
    print(f"checked {len(paths)} chart markdown files, {len(bad)} relative link(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
