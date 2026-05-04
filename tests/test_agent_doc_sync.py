import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SKIP_PARTS = {".git", "__pycache__", ".pytest_cache", ".mypy_cache", ".venv", "venv", "node_modules"}


def agent_docs() -> list[Path]:
    return sorted(
        path for path in PROJECT_ROOT.rglob("AGENTS.md")
        if not any(part in SKIP_PARTS for part in path.relative_to(PROJECT_ROOT).parts)
    )


def test_every_agents_doc_has_identical_claude_mirror():
    docs = agent_docs()
    assert docs
    for agents_doc in docs:
        claude_doc = agents_doc.with_name("CLAUDE.md")
        assert claude_doc.exists(), f"Missing mirror for {agents_doc.relative_to(PROJECT_ROOT)}"
        assert claude_doc.read_text(encoding="utf-8") == agents_doc.read_text(encoding="utf-8")


def test_agent_doc_sync_check_passes():
    result = subprocess.run(
        [sys.executable, "scripts/sync_agent_docs.py", "--check"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert "CLAUDE.md mirror(s) are in sync" in result.stdout
