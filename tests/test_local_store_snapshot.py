from datetime import UTC, datetime

from fastapi.testclient import TestClient

from core.bundles import local_store_snapshot_to_bundle, validate_local_store_snapshot
from core.contracts import (
    LocalStoreMetadata,
    LocalStoreSnapshot,
    LocalStoreSnapshotValidationRequest,
    ObservationEvent,
    RecordLifecycle,
    Subject,
)
from core.tracking import default_tracker_settings
from server import app


def _snapshot() -> LocalStoreSnapshot:
    now = datetime(2026, 5, 2, 10, 0, tzinfo=UTC)
    subject = Subject(id="subject-1", timezone="UTC", locale="en-US")
    settings = default_tracker_settings(subject.id)
    event = ObservationEvent(
        id="obs-1",
        subject_id=subject.id,
        tracker_code="cramps",
        observed_at=now,
        source="user_entered",
        value="mild",
    )
    return LocalStoreSnapshot(
        metadata=LocalStoreMetadata(
            schema_version="2026.05.02",
            app_version="period-flutter-dev",
            device_timezone="UTC",
            created_at=now,
            updated_at=now,
        ),
        subject=subject,
        tracker_settings=settings,
        observations=[event],
        record_lifecycle={
            subject.id: RecordLifecycle(created_at=now, updated_at=now),
            f"tracker_settings:{subject.id}": RecordLifecycle(created_at=now, updated_at=now),
            event.id: RecordLifecycle(created_at=now, updated_at=now),
        },
    )


def test_local_store_snapshot_validates_object_graph():
    result = validate_local_store_snapshot(_snapshot())
    assert result.ok is True
    assert result.status == "accepted"
    assert result.errors == []
    assert result.observation_results[0].ok is True


def test_local_store_snapshot_to_bundle_preserves_export_shape():
    snapshot = _snapshot()
    bundle = local_store_snapshot_to_bundle(snapshot)
    assert bundle.schema_version == snapshot.metadata.schema_version
    assert bundle.subject.id == snapshot.subject.id
    assert bundle.tracker_settings == snapshot.tracker_settings
    assert bundle.observations == snapshot.observations


def test_local_store_snapshot_rejects_unknown_lifecycle_key_and_subject_mismatch():
    snapshot = _snapshot()
    snapshot.tracker_settings.subject_id = "other-subject"
    snapshot.record_lifecycle["missing-record"] = RecordLifecycle(
        created_at=snapshot.metadata.created_at,
        updated_at=snapshot.metadata.updated_at,
    )
    result = validate_local_store_snapshot(snapshot)
    assert result.ok is False
    assert result.status == "accepted_with_warnings"
    assert "tracker_settings_subject_mismatch" in result.errors
    assert "lifecycle_unknown_record_id:missing-record" in result.errors


def test_local_store_snapshot_endpoint_is_stateless():
    client = TestClient(app)
    request = LocalStoreSnapshotValidationRequest(snapshot=_snapshot())
    response = client.post("/api/v1/validate-local-store-snapshot", json=request.model_dump(mode="json"))
    assert response.status_code == 200
    assert response.json()["ok"] is True
