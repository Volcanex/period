"""Validation helpers for Flutter's local on-device store snapshot."""

from __future__ import annotations

from core.contracts import LocalDataBundle, LocalStoreSnapshot, LocalDataBundleValidationResult
from core.contracts.versioning import check_contract_compatibility
from core.tracking import resolve_tracker_settings, validate_observation_event


def _owned_ids(snapshot: LocalStoreSnapshot) -> set[str]:
    ids = {snapshot.subject.id}
    ids.add(f"tracker_settings:{snapshot.tracker_settings.subject_id}")
    ids.update(event.id for event in snapshot.observations)
    ids.update(projection.id for projection in snapshot.cycle_projections)
    ids.update(prediction.id for prediction in snapshot.predictions)
    ids.update(report.id for report in snapshot.reports)
    return ids


def local_store_snapshot_to_bundle(snapshot: LocalStoreSnapshot) -> LocalDataBundle:
    """Convert a full local store snapshot into the user-controlled export bundle shape."""
    return LocalDataBundle(
        schema_version=snapshot.metadata.schema_version,
        app_version=snapshot.metadata.app_version,
        exported_at=snapshot.metadata.last_exported_at or snapshot.metadata.updated_at,
        subject=snapshot.subject,
        tracker_settings=snapshot.tracker_settings,
        observations=snapshot.observations,
        cycle_projections=snapshot.cycle_projections,
        predictions=snapshot.predictions,
        reports=snapshot.reports,
    )


def validate_local_store_snapshot(snapshot: LocalStoreSnapshot) -> LocalDataBundleValidationResult:
    """Validate the on-device object graph without introducing backend storage or sync."""
    errors: list[str] = []
    warnings: list[str] = []
    compatibility = check_contract_compatibility(snapshot.metadata.schema_version)
    errors.extend(compatibility.errors)
    warnings.extend(compatibility.warnings)

    subject_id = snapshot.subject.id
    if snapshot.tracker_settings.subject_id != subject_id:
        errors.append("tracker_settings_subject_mismatch")

    settings_result = resolve_tracker_settings(snapshot.tracker_settings)
    if not settings_result.ok:
        errors.extend(f"tracker_settings_{error}" for error in settings_result.errors)
    warnings.extend(f"tracker_settings_{warning}" for warning in settings_result.warnings)

    observation_results = []
    for event in snapshot.observations:
        if event.subject_id != subject_id:
            errors.append(f"observation_subject_mismatch:{event.id}")
        result = validate_observation_event(event)
        observation_results.append(result)
        if not result.ok:
            errors.append(f"observation_invalid:{event.id}")

    for projection in snapshot.cycle_projections:
        if projection.subject_id != subject_id:
            errors.append(f"cycle_projection_subject_mismatch:{projection.id}")

    for prediction in snapshot.predictions:
        if prediction.subject_id != subject_id:
            errors.append(f"prediction_subject_mismatch:{prediction.id}")

    for report in snapshot.reports:
        if report.subject_id != subject_id:
            errors.append(f"report_subject_mismatch:{report.id}")

    owned_ids = _owned_ids(snapshot)
    for record_id in snapshot.record_lifecycle:
        if record_id not in owned_ids:
            errors.append(f"lifecycle_unknown_record_id:{record_id}")

    status = compatibility.status
    if errors:
        status = "unsupported_version" if compatibility.status == "unsupported_version" else "accepted_with_warnings"
    elif warnings:
        status = "accepted_with_warnings"

    return LocalDataBundleValidationResult(
        ok=not errors,
        status=status,
        errors=errors,
        warnings=warnings,
        observation_results=observation_results,
    )
