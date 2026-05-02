"""Validation for local-first export/import bundles."""

from __future__ import annotations

from core.contracts import LocalDataBundle, LocalDataBundleValidationResult
from core.contracts.versioning import check_contract_compatibility
from core.tracking import resolve_tracker_settings, validate_observation_event


def validate_local_data_bundle(bundle: LocalDataBundle) -> LocalDataBundleValidationResult:
    """Validate cross-object integrity without persisting or calculating server-side state."""
    errors: list[str] = []
    warnings: list[str] = []
    compatibility = check_contract_compatibility(bundle.schema_version)
    errors.extend(compatibility.errors)
    warnings.extend(compatibility.warnings)
    subject_id = bundle.subject.id

    if bundle.tracker_settings is not None:
        if bundle.tracker_settings.subject_id != subject_id:
            errors.append("tracker_settings_subject_mismatch")
        settings_result = resolve_tracker_settings(bundle.tracker_settings)
        if not settings_result.ok:
            errors.extend(f"tracker_settings_{error}" for error in settings_result.errors)

    observation_results = []
    for event in bundle.observations:
        if event.subject_id != subject_id:
            errors.append(f"observation_subject_mismatch:{event.id}")
        result = validate_observation_event(event)
        observation_results.append(result)
        if not result.ok:
            errors.append(f"observation_invalid:{event.id}")

    for projection in bundle.cycle_projections:
        if projection.subject_id != subject_id:
            errors.append(f"cycle_projection_subject_mismatch:{projection.id}")

    for prediction in bundle.predictions:
        if prediction.subject_id != subject_id:
            errors.append(f"prediction_subject_mismatch:{prediction.id}")

    for report in bundle.reports:
        if report.subject_id != subject_id:
            errors.append(f"report_subject_mismatch:{report.id}")

    status = compatibility.status
    if errors:
        status = "unsupported_version" if compatibility.status == "unsupported_version" else "accepted_with_warnings"

    return LocalDataBundleValidationResult(
        ok=not errors,
        status=status,
        errors=errors,
        warnings=warnings,
        observation_results=observation_results,
    )
