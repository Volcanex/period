#!/usr/bin/env python3
"""Build an auto-generated index of every AGENTS.md in the repo and mirror CLAUDE.md."""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.sync_agent_docs import sync as sync_agent_docs
SKIP_DIRS = {
    "output", "venv", ".venv", "__pycache__", ".git", "node_modules",
    ".mypy_cache", ".pytest_cache", ".claude", "dist", "build",
}
START_MARKER = "<!-- DOCS:START -->"
END_MARKER = "<!-- DOCS:END -->"
DOC_NAME = "AGENTS.md"


def first_heading(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("# "):
            return line[2:].strip()
    return path.parent.name


def discover() -> list[dict[str, str]]:
    docs = []
    for md in sorted(PROJECT_ROOT.rglob(DOC_NAME)):
        rel = md.relative_to(PROJECT_ROOT)
        if str(rel) == DOC_NAME:
            continue
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        docs.append({"path": str(rel), "heading": first_heading(md)})
    return docs


def table(docs: list[dict[str, str]]) -> str:
    lines = ["| Path | Summary |", "|------|---------|"]
    for doc in docs:
        lines.append("| `" + doc["path"] + "` | " + doc["heading"] + " |")
    return "\n".join(lines)


def main() -> None:
    root = PROJECT_ROOT / DOC_NAME
    if not root.exists():
        raise SystemExit(f"ERROR: no root {DOC_NAME} found")
    content = root.read_text(encoding="utf-8")
    if START_MARKER not in content or END_MARKER not in content:
        raise SystemExit(
            f"ERROR: root {DOC_NAME} missing sentinels.\n"
            f"Add this block where you want the index:\n\n"
            f"{START_MARKER}\n{END_MARKER}"
        )
    docs = discover()
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    body = table(docs) if docs else f"_No subdirectory {DOC_NAME} files yet._"
    block = (
        f"{START_MARKER}\n{body}\n\n"
        f"_Auto-compiled {timestamp} - {len(docs)} doc(s) found._\n"
        f"{END_MARKER}"
    )
    start = content.index(START_MARKER)
    end = content.index(END_MARKER) + len(END_MARKER)
    root.write_text(content[:start] + block + content[end:], encoding="utf-8")
    sync_agent_docs(check=False)
    print(f"Indexed {len(docs)} {DOC_NAME} file(s):")
    for doc in docs:
        print("  " + doc["path"] + " - " + doc["heading"])


if __name__ == "__main__":
    main()
