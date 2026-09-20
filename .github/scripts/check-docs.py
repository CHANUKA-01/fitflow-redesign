#!/usr/bin/env python3
"""Validate the documentation set: required artefacts exist and every relative link resolves.

Run from the repository root:  python3 .github/scripts/check-docs.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[2]

REQUIRED = [
    "README.md",
    "CONTRIBUTING.md",
    "LICENSE",
    ".env.example",
    "docs/01-frontend-comparison.md",
    "docs/02-backend-comparison.md",
    "docs/03-decision-matrix.md",
    "docs/04-architecture.md",
    "docs/05-requirements-trace.md",
    "docs/adr/ADR-001-technology-stack.md",
    "docs/adr/ADR-002-postgresql-source-of-truth.md",
    "docs/adr/ADR-003-on-device-food-recognition.md",
    "docs/adr/ADR-004-authorisation-in-the-api.md",
    "docs/diagrams/architecture.png",
    "docs/diagrams/architecture.svg",
]

# [text](target) — skips images only in that the leading ! is allowed and ignored.
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")

SKIP_DIRS = {".git", "node_modules", ".venv", ".dart_tool", "build", ".next"}


def markdown_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.md")
        if not SKIP_DIRS.intersection(path.relative_to(ROOT).parts)
    )


def broken_links(path: Path) -> list[str]:
    problems: list[str] = []
    for match in LINK.finditer(path.read_text(encoding="utf-8")):
        target = match.group(1).strip().split(" ", 1)[0]
        if not target or target.startswith(("#", "mailto:")):
            continue
        if urlparse(target).scheme:  # http, https, etc. — not our business offline
            continue
        resolved = (path.parent / unquote(target.split("#", 1)[0])).resolve()
        if not resolved.exists():
            problems.append(f"{path.relative_to(ROOT)}: link target not found -> {target}")
    return problems


def main() -> int:
    failures = [f"missing required artefact -> {name}" for name in REQUIRED if not (ROOT / name).exists()]

    files = markdown_files()
    for path in files:
        failures.extend(broken_links(path))

    for failure in failures:
        print(f"error: {failure}")

    if failures:
        print(f"\n{len(failures)} problem(s) found.")
        return 1

    print(f"Checked {len(files)} markdown file(s) and {len(REQUIRED)} required artefact(s): all good.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
