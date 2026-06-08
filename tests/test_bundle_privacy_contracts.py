from datetime import UTC, datetime

from core.bundles import validate_local_data_bundle
from core.contracts import LocalDataBundle, LocalDataBundleValidationRequest, ObservationEvent, Subject
from core.contracts.versioning import CURRENT_CONTRACT_VERSION
from core.privacy import privacy_manifest
from server import app
from tests.http_client import SyncASGIClient


def _bundle(event: ObservationEvent) -> LocalDataBundle:
    return LocalDataBundle(
        schema_version=CURRENT_CONTRACT_VERSION,
        exported_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        subject=Subject(id="subject-1", birth_year=1990, timezone="UTC", locale="en-US"),
        observations=[event],
    )


def test_local_data_bundle_validation_accepts_valid_observations():
    event = ObservationEvent(
        id="obs-1",
        subject_id="subject-1",
        tracker_code="cramps",
        observed_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        source="user_entered",
        value="mild",
    )
    result = validate_local_data_bundle(_bundle(event))
    assert result.ok is True
    assert result.errors == []
    assert result.observation_results[0].ok is True


def test_local_data_bundle_validation_reports_subject_and_tracker_errors():
    event = ObservationEvent(
        id="obs-2",
        subject_id="other-subject",
        tracker_code="cramps",
        observed_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        source="user_entered",
        value="impossible",
    )
    result = validate_local_data_bundle(_bundle(event))
    assert result.ok is False
    assert "observation_subject_mismatch:obs-2" in result.errors
    assert "observation_invalid:obs-2" in result.errors


def test_validate_local_data_bundle_endpoint_is_contract_only():
    client = SyncASGIClient(app)
    event = ObservationEvent(
        id="obs-3",
        subject_id="subject-1",
        tracker_code="sleep_hours",
        observed_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        source="user_entered",
        value=8.0,
        unit="hours",
    )
    request = LocalDataBundleValidationRequest(bundle=_bundle(event))
    response = client.post("/api/v1/validate-local-data-bundle", json=request.model_dump(mode="json"))
    assert response.status_code == 200
    assert response.json()["ok"] is True


def test_privacy_manifest_keeps_user_health_data_device_owned():
    manifest = privacy_manifest()
    entries = {entry.code: entry for entry in manifest.entries}
    for code in ["subject_profile", "observation_events", "cycle_projections", "predictions", "reports"]:
        assert entries[code].owner == "device"
        assert entries[code].leaves_device_by_default is False
        assert entries[code].server_persists is False


def test_privacy_manifest_endpoint_matches_contract():
    client = SyncASGIClient(app)
    response = client.get("/api/v1/privacy-manifest")
    assert response.status_code == 200
    assert response.json()["posture"] == "local_first_private"
