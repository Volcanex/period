from datetime import UTC, datetime

from core.bundles import validate_local_data_bundle
from core.contracts import (
    LocalDataBundle,
    Subject,
    TrackerPreference,
    TrackerSettings,
    TrackerSettingsResolutionRequest,
)
from core.tracking import default_tracker_settings, resolve_tracker_settings
from server import app
from tests.http_client import SyncASGIClient


def test_default_tracker_settings_enable_base_pack_only():
    settings = default_tracker_settings("subject-1")
    assert settings.subject_id == "subject-1"
    assert settings.enabled_pack_codes == ["base_symptoms"]
    assert settings.disabled_tracker_codes == []

    result = resolve_tracker_settings(settings)
    assert result.ok is True
    assert result.active_catalog is not None
    codes = [definition.code for definition in result.active_catalog.tracker_definitions]
    assert "period_bleeding" in codes
    assert "acne_severity" not in codes


def test_tracker_settings_can_enable_pack_and_pin_tracker_order():
    settings = TrackerSettings(
        subject_id="subject-1",
        enabled_pack_codes=["base_symptoms", "pcos_support"],
        disabled_tracker_codes=["sex"],
        tracker_preferences=[
            TrackerPreference(tracker_code="acne_severity", enabled=True, pinned=True, display_order=0),
            TrackerPreference(tracker_code="sex", enabled=False),
        ],
        updated_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        schema_version="2026.05.02",
    )
    result = resolve_tracker_settings(settings)
    assert result.ok is True
    assert result.active_catalog is not None
    codes = [definition.code for definition in result.active_catalog.tracker_definitions]
    assert codes[0] == "acne_severity"
    assert "cycle_regularity" in codes
    assert "hair_growth" in codes
    assert "sex" not in codes


def test_tracker_settings_reject_unknown_codes_and_duplicates():
    settings = TrackerSettings(
        subject_id="subject-1",
        enabled_pack_codes=["not_a_pack"],
        disabled_tracker_codes=["not_a_tracker"],
        tracker_preferences=[
            TrackerPreference(tracker_code="cramps"),
            TrackerPreference(tracker_code="cramps"),
            TrackerPreference(tracker_code="not_a_tracker"),
        ],
        updated_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        schema_version="2026.05.02",
    )
    result = resolve_tracker_settings(settings)
    assert result.ok is False
    assert "unknown_pack_code:not_a_pack" in result.errors
    assert "unknown_disabled_tracker_code:not_a_tracker" in result.errors
    assert "duplicate_tracker_preference:cramps" in result.errors
    assert "unknown_preference_tracker_code:not_a_tracker" in result.errors


def test_tracker_settings_endpoints_are_stateless_contract_helpers():
    client = SyncASGIClient(app)
    response = client.get("/api/v1/tracker-settings/default", params={"subject_id": "subject-1"})
    assert response.status_code == 200
    settings = TrackerSettings.model_validate(response.json())

    resolve_response = client.post(
        "/api/v1/tracker-settings/resolve",
        json=TrackerSettingsResolutionRequest(settings=settings).model_dump(mode="json"),
    )
    assert resolve_response.status_code == 200
    assert resolve_response.json()["ok"] is True
    assert resolve_response.json()["active_catalog"]["subject_id"] == "subject-1"


def test_local_data_bundle_validation_checks_tracker_settings_subject():
    bundle = LocalDataBundle(
        schema_version="2026.05.02",
        exported_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        subject=Subject(id="subject-1", timezone="UTC", locale="en-US"),
        tracker_settings=default_tracker_settings("other-subject"),
    )
    result = validate_local_data_bundle(bundle)
    assert result.ok is False
    assert "tracker_settings_subject_mismatch" in result.errors
