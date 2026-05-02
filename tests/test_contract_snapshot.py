import json
import subprocess
import sys
from pathlib import Path

from core.contracts import ContractCompatibilityResult, ContractVersion, LocalDataBundle, LocalStoreSnapshot, PrivacyManifest, TrackerDefinition, TrackerPack

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SNAPSHOT_DIR = PROJECT_ROOT / "contract_snapshot"


def _validate(model, payload):
    if hasattr(model, "model_validate"):
        return model.model_validate(payload)
    return model.parse_obj(payload)


def test_export_contracts_generates_openapi_and_examples():
    result = subprocess.run([sys.executable, "scripts/export_contracts.py"], cwd=PROJECT_ROOT, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr

    openapi = json.loads((SNAPSHOT_DIR / "openapi.v1.json").read_text(encoding="utf-8"))
    assert "/api/v1/app-config" in openapi["paths"]
    assert "/api/v1/privacy-manifest" in openapi["paths"]
    assert "CalendarFeed" in openapi["components"]["schemas"]
    assert "LocalDataBundle" in openapi["components"]["schemas"]
    assert "LocalStoreSnapshot" in openapi["components"]["schemas"]
    assert "ContractVersion" in openapi["components"]["schemas"]

    _validate(ContractVersion, json.loads((SNAPSHOT_DIR / "contract-version.v1.json").read_text(encoding="utf-8")))
    changelog = json.loads((SNAPSHOT_DIR / "contract-changelog.v1.json").read_text(encoding="utf-8"))
    assert changelog[0]["version"] == "2026.05.02"

    examples = SNAPSHOT_DIR / "examples"
    _validate(TrackerDefinition, json.loads((examples / "tracker-definition.period-bleeding.json").read_text(encoding="utf-8")))
    _validate(TrackerPack, json.loads((examples / "tracker-pack.endometriosis-support.json").read_text(encoding="utf-8")))
    _validate(LocalStoreSnapshot, json.loads((examples / "local-store-snapshot.demo.json").read_text(encoding="utf-8")))
    _validate(LocalDataBundle, json.loads((examples / "local-data-bundle.demo.json").read_text(encoding="utf-8")))
    _validate(PrivacyManifest, json.loads((examples / "privacy-manifest.v1.json").read_text(encoding="utf-8")))
    _validate(ContractCompatibilityResult, json.loads((examples / "contract-compatibility.accepted.json").read_text(encoding="utf-8")))
    _validate(ContractCompatibilityResult, json.loads((examples / "contract-compatibility.unsupported.json").read_text(encoding="utf-8")))
