from datetime import UTC, datetime

from fastapi.testclient import TestClient

from core.contracts import ObservationEvent, ObservationValidationRequest, TrackerPack
from core.tracking import tracker_definitions, tracker_packs, tracker_registry, validate_observation_event
from server import app


def test_base_symptoms_are_universal_and_pcos_is_a_pack():
    packs = {pack.code: pack for pack in tracker_packs()}
    assert isinstance(packs["base_symptoms"], TrackerPack)
    assert packs["base_symptoms"].enabled_by_default is True
    assert "period_bleeding" in packs["base_symptoms"].tracker_codes
    assert "pcos_support" in packs
    assert "acne_severity" in packs["pcos_support"].tracker_codes
    assert "period_bleeding" in packs["pcos_support"].tracker_codes
    assert "does not infer or diagnose PCOS" in packs["pcos_support"].clinical_note


def test_tracker_registry_has_unique_codes():
    definitions = tracker_definitions()
    codes = [definition.code for definition in definitions]
    assert len(codes) == len(set(codes))
    assert set(tracker_registry()) == set(codes)


def test_validate_observation_accepts_valid_symptom_event():
    event = ObservationEvent(
        id="obs-cramps-1",
        subject_id="subject-1",
        tracker_code="cramps",
        observed_at=datetime.now(UTC),
        source="user_entered",
        value="moderate",
    )
    result = validate_observation_event(event)
    assert result.ok is True
    assert result.errors == []


def test_validate_observation_rejects_invalid_enum_value():
    event = ObservationEvent(
        id="obs-cramps-2",
        subject_id="subject-1",
        tracker_code="cramps",
        observed_at=datetime.now(UTC),
        source="user_entered",
        value="gigantic",
    )
    result = validate_observation_event(event)
    assert result.ok is False
    assert "value_not_allowed" in result.errors


def test_validate_observation_endpoint_round_trip():
    client = TestClient(app)
    event = ObservationEvent(
        id="obs-temp-1",
        subject_id="subject-1",
        tracker_code="basal_body_temperature",
        observed_at=datetime.now(UTC),
        source="user_entered",
        value=36.6,
        unit="celsius",
    )
    response = client.post(
        "/api/v1/validate-observation",
        json=ObservationValidationRequest(event=event).model_dump(mode="json"),
    )
    assert response.status_code == 200
    assert response.json() == {"ok": True, "tracker_code": "basal_body_temperature", "errors": []}


def test_tracker_pack_endpoint_exposes_pcos_pack():
    client = TestClient(app)
    response = client.get("/api/v1/tracker-packs")
    assert response.status_code == 200
    packs = {pack["code"]: pack for pack in response.json()}
    assert "base_symptoms" in packs
    assert "pcos_support" in packs
