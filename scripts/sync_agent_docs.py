#!/usr/bin/env python3
"""Mirror AGENTS.md guidance into CLAUDE.md for Claude Code compatibility."""

from __future__ import annotations

import argparse
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {
    "output", "venv", ".venv", "__pycache__", ".git", "node_modules",
    ".mypy_cache", ".pytest_cache", ".claude", "dist", "build",
}
SOURCE_NAME = "AGENTS.md"
MIRROR_NAME = "CLAUDE.md"


def should_skip(path: Path) -> bool:
    rel = path.relative_to(PROJECT_ROOT)
    return any(part in SKIP_DIRS for part in rel.parts)


def agent_docs() -> list[Path]:
    return sorted(path for path in PROJECT_ROOT.rglob(SOURCE_NAME) if not should_skip(path))


def mirror_for(agent_doc: Path) -> Path:
    return agent_doc.with_name(MIRROR_NAME)


def sync(check: bool = False) -> int:
    failures: list[str] = []
    mirrored = 0
    for agent_doc in agent_docs():
        mirror = mirror_for(agent_doc)
        source = agent_doc.read_text(encoding="utf-8")
        existing = mirror.read_text(encoding="utf-8") if mirror.exists() else None
        if existing != source:
            rel = mirror.relative_to(PROJECT_ROOT)
            if check:
                failures.append(str(rel))
            else:
                mirror.write_text(source, encoding="utf-8")
                mirrored += 1
    if failures:
        print("CLAUDE.md mirrors are out of sync:")
        for failure in failures:
            print(f"  {failure}")
        return 1
    if check:
        print(f"All {len(agent_docs())} CLAUDE.md mirror(s) are in sync.")
    else:
        print(f"Mirrored {mirrored} CLAUDE.md file(s) from {len(agent_docs())} AGENTS.md file(s).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if any CLAUDE.md mirror is missing or stale.")
    args = parser.parse_args()
    return sync(check=args.check)


if __name__ == "__main__":
    raise SystemExit(main())
