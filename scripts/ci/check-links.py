#!/usr/bin/env python3
"""Validate markdown links across the repo's docs.

Usage: scripts/ci/check-links.py [path ...]   (default: every tracked .md below)
Mirrors `task check-links`.

Why this exists: ArtifactHub renders only the packaged chart README, and its
renderer accepts exactly two kinds of link. It tests `/^https?:/` for external
ones, and for the rest falls through to `href.startsWith('#') && isElementInView`
-> a scroll button. Anything else is dropped: the href is discarded and the text
renders as plain, unclickable prose. A relative path is not rewritten to the
source repo and a relative image renders as nothing at all.

Both failure modes are invisible from here — on GitHub the target file is local,
so a relative link works and an in-page anchor to a heading that has since moved
to another file simply scrolls nowhere. Neither shows up in a diff. PR #186 moved
every migration section out of the chart READMEs and broke three separate classes
of link this way, all found by hand.

The rules, in the order the checker applies them:

  * `#anchor`      -> must match a heading slug in the SAME file. Level-independent
                      but not file-independent; this is the one that breaks when
                      prose moves.
  * `https?:`      -> not fetched (no network in this gate), but a link into this
                      repo's own `blob/main/` tree is resolved on disk, path and
                      anchor both. That is the form every cross-file chart link
                      must take, so it is worth checking.
  * anything else  -> a relative link. Banned under `charts/` because that is what
                      ArtifactHub silently drops; allowed in the repo-side docs
                      (README.md, CONTRIBUTING.md), which only ever render on
                      GitHub, but the target still has to exist.

Slugging is github-slugger's algorithm, verified against GitHub's rendered HTML
rather than assumed: lowercase, strip punctuation (dots and backticks go, `-` and
`_` survive), spaces to `-`, `-1`/`-2` suffixes for duplicates.
"""

import subprocess
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BLOB = "https://github.com/homeylab/helm-charts/blob/main/"

# Fenced code blocks hold ~190 lines of YAML and shell comments in this repo, and
# every `#` one of them starts looks like a heading. Strip them before anything else.
FENCE = re.compile(r"^```.*?^```", re.S | re.M)
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*(?:<!--.*-->)?\s*$", re.M)
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)\)")


def strip_code(text):
    return FENCE.sub("", text)


def slugs(text):
    """Heading slugs for one file, in github-slugger form."""
    seen, out = {}, set()
    for _, raw in HEADING.findall(strip_code(text)):
        title = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", raw).replace("`", "")
        s = re.sub(r"\s+", "-", re.sub(r"[^\w\s-]", "", title.strip().lower()))
        n = seen.get(s, 0)
        seen[s] = n + 1
        out.add(s if n == 0 else f"{s}-{n}")
    return out


def check(paths):
    cache = {p: slugs(p.read_text()) for p in paths}
    errors = []

    def anchors_for(path):
        if path not in cache:
            cache[path] = slugs(path.read_text())
        return cache[path]

    for path in paths:
        rel = path.relative_to(REPO)
        in_chart = str(rel).startswith("charts/")
        for href in LINK.findall(strip_code(path.read_text())):
            if href.startswith("#"):
                if href[1:] not in cache[path]:
                    errors.append(f"{rel}: in-page anchor has no matching heading: {href}")
            elif href.startswith(BLOB):
                target, _, anchor = href[len(BLOB):].partition("#")
                resolved = REPO / target
                if not resolved.exists():
                    errors.append(f"{rel}: links to a path that does not exist: {target}")
                elif anchor and resolved.suffix == ".md" and anchor not in anchors_for(resolved):
                    errors.append(f"{rel}: anchor not found in {target}: #{anchor}")
            elif re.match(r"^[a-z][a-z0-9+.-]*:", href) or href.startswith("//"):
                pass  # some other scheme (https elsewhere, mailto:, …) — nothing to resolve
            elif in_chart:
                errors.append(
                    f"{rel}: relative link — ArtifactHub drops these silently, use the full "
                    f"{BLOB}… URL: {href}"
                )
            else:
                target = (path.parent / href.split("#", 1)[0]).resolve()
                if not target.exists():
                    errors.append(f"{rel}: relative link to a path that does not exist: {href}")
    return errors


def main():
    args = sys.argv[1:]
    if args:
        paths = [Path(a).resolve() for a in args]
    else:
        # Tracked files only. Locally this repo also holds gitignored scratch under
        # .claude/_plans/, which CI never checks out and nobody should be gated on.
        listed = subprocess.run(
            ["git", "-C", str(REPO), "ls-files", "-z", "*.md"],
            capture_output=True, text=True, check=True,
        ).stdout
        paths = sorted(REPO / p for p in listed.split("\0") if p)

    errors = check(paths)
    for e in errors:
        print(f"error: {e}", file=sys.stderr)
    print(f"checked {len(paths)} markdown files, {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
