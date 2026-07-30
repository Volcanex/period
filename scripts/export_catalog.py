"""Export the canonical tracker catalog to the Flutter client's asset bundle.

The client is offline-only: it ships the catalog rather than fetching it. This
script is the regeneration path, so the bundled JSON can be re-derived from the
Python registry instead of being hand-maintained and drifting away from it.

Run from the repo root after changing anything in `core/tracking/registry.py`:

    .venv/bin/python scripts/export_catalog.py
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.tracking.registry import tracker_definitions, tracker_packs  # noqa: E402

OUT_DIR = Path(__file__).resolve().parent.parent / "app" / "assets" / "catalog"


def _dump(name, payload):
    path = OUT_DIR / name
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    return path, len(payload)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    definitions = [d.model_dump(mode="json") for d in tracker_definitions()]
    packs = [p.model_dump(mode="json") for p in tracker_packs()]
    for name, payload in (
        ("tracker_definitions.json", definitions),
        ("tracker_packs.json", packs),
    ):
        path, count = _dump(name, payload)
        print(f"wrote {count:>3} entries -> {path.relative_to(OUT_DIR.parents[2])}")


if __name__ == "__main__":
    main()
