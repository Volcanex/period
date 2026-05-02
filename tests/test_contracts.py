import json
from pathlib import Path

from fastapi.testclient import TestClient

from core.contracts import AnalysisResult, Analyzer, AppConfig, CalendarFeed, ContractVersion, CycleProjection, LocalDataBundle, LocalStoreSnapshot, ObservationEvent, Prediction, PrivacyManifest, Report, Subject, TrackerDefinition, TrackerSettings
from core.contracts.registry import tracker_definitions
from server import app

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FIXTURES = PROJECT_ROOT / "tests" / "fixtures"


def load_fixture(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def validate(model, payload: dict):
    if hasattr(model, "model_validate"):
        return model.model_validate(payload)
    return model.parse_obj(payload)


def test_health_endpoint_returns_stable_json():
    client = TestClient(app)
    response = client.get("/api/_health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_app_config_endpoint_matches_contract():
    client = TestClient(app)
    response = client.get("/api/v1/app-config")
    assert response.status_code == 200
    config = validate(AppConfig, response.json())
    assert config.api_version == "v1"
    assert config.calculation_owner == "device"
    assert config.privacy_posture == "local_first_private"


def test_tracker_definitions_endpoint_matches_contract():
    client = TestClient(app)
    response = client.get("/api/v1/tracker-definitions")
    assert response.status_code == 200
    definitions = [validate(TrackerDefinition, item) for item in response.json()]
    assert definitions
    assert definitions == tracker_definitions()


def test_domain_fixtures_validate_against_contracts():
    cases = {
        "subject.json": Subject,
        "observation_event.json": ObservationEvent,
        "cycle_projection.json": CycleProjection,
        "prediction.json": Prediction,
        "analyzer.json": Analyzer,
        "analysis_result.json": AnalysisResult,
        "report.json": Report,
    }
    for fixture, model in cases.items():
        validate(model, load_fixture(fixture))


def test_openapi_includes_v1_routes_and_domain_schemas():
    client = TestClient(app)
    response = client.get("/openapi.json")
    assert response.status_code == 200
    spec = response.json()
    assert "/api/v1/app-config" in spec["paths"]
    assert "/api/v1/contract-version" in spec["paths"]
    assert "/api/v1/contract-compatibility" in spec["paths"]
    assert "/api/v1/tracker-definitions" in spec["paths"]
    assert "/api/v1/tracker-packs" in spec["paths"]
    assert "/api/v1/privacy-manifest" in spec["paths"]
    assert "/api/v1/tracker-settings/default" in spec["paths"]
    assert "/api/v1/tracker-settings/resolve" in spec["paths"]
    assert "/api/v1/validate-local-data-bundle" in spec["paths"]
    assert "/api/v1/validate-local-store-snapshot" in spec["paths"]
    schemas = spec["components"]["schemas"]
    for name in ["AppConfig", "TrackerDefinition", "Subject", "ObservationEvent", "CycleProjection", "Prediction", "Analyzer", "AnalysisResult", "Report", "CalendarFeed", "LocalDataBundle", "PrivacyManifest", "TrackerSettings", "ActiveTrackerCatalog", "ContractVersion", "ContractCompatibilityResult", "LocalStoreSnapshot", "RecordLifecycle"]:
        assert name in schemas


def test_agents_docs_compiler_indexes_nested_docs():
    import subprocess
    import sys

    result = subprocess.run([sys.executable, "scripts/compile_docs.py"], cwd=PROJECT_ROOT, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    root_doc = (PROJECT_ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert "<!-- DOCS:START -->" in root_doc
    assert "core/AGENTS.md" in root_doc
    assert "core/contracts/AGENTS.md" in root_doc
    assert "tests/AGENTS.md" in root_doc
