from datetime import UTC, datetime

from fastapi.testclient import TestClient

from core.bundles import validate_local_data_bundle
from core.contracts import ContractCompatibilityRequest, ContractVersion, LocalDataBundle, Subject
from core.contracts.versioning import CURRENT_CONTRACT_VERSION, check_contract_compatibility, contract_version
from server import app


def test_contract_version_declares_current_support_window_and_policy():
    version = contract_version()
    assert isinstance(version, ContractVersion)
    assert version.current_version == CURRENT_CONTRACT_VERSION
    assert version.minimum_supported_version == CURRENT_CONTRACT_VERSION
    assert version.supported_versions == [CURRENT_CONTRACT_VERSION]
    assert version.changelog[0].change_type == "initial"
    assert "Breaking changes" in version.compatibility_policy


def test_contract_compatibility_accepts_current_and_rejects_unknown():
    accepted = check_contract_compatibility(CURRENT_CONTRACT_VERSION)
    assert accepted.status == "accepted"
    assert accepted.errors == []

    unsupported = check_contract_compatibility("2026.01.01")
    assert unsupported.status == "unsupported_version"
    assert unsupported.migration_required is True
    assert "unsupported_contract_version" in unsupported.errors


def test_contract_version_endpoints_round_trip():
    client = TestClient(app)
    version_response = client.get("/api/v1/contract-version")
    assert version_response.status_code == 200
    assert version_response.json()["current_version"] == CURRENT_CONTRACT_VERSION

    compatibility_response = client.post(
        "/api/v1/contract-compatibility",
        json=ContractCompatibilityRequest(schema_version=CURRENT_CONTRACT_VERSION).model_dump(mode="json"),
    )
    assert compatibility_response.status_code == 200
    assert compatibility_response.json()["status"] == "accepted"


def test_bundle_validation_rejects_unsupported_schema_version():
    bundle = LocalDataBundle(
        schema_version="2026.01.01",
        exported_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        subject=Subject(id="subject-1", timezone="UTC", locale="en-US"),
    )
    result = validate_local_data_bundle(bundle)
    assert result.ok is False
    assert result.status == "unsupported_version"
    assert "unsupported_contract_version" in result.errors
