"""Tracker personalization contracts for Atlas."""

from __future__ import annotations

from datetime import UTC, datetime

from core.contracts import (
    ActiveTrackerCatalog,
    TrackerDefinition,
    TrackerPreference,
    TrackerSettings,
    TrackerSettingsValidationResult,
)
from core.tracking.registry import tracker_packs, tracker_registry

SCHEMA_VERSION = "2026.05.02"


def default_tracker_settings(subject_id: str) -> TrackerSettings:
    """Return device-owned default settings with only default packs enabled."""
    return TrackerSettings(
        subject_id=subject_id,
        enabled_pack_codes=[pack.code for pack in tracker_packs() if pack.enabled_by_default],
        disabled_tracker_codes=[],
        tracker_preferences=[],
        updated_at=datetime.now(UTC),
        schema_version=SCHEMA_VERSION,
    )


def _ordered_definitions(definitions: list[TrackerDefinition], preferences: dict[str, TrackerPreference]) -> list[TrackerDefinition]:
    def key(definition: TrackerDefinition):
        preference = preferences.get(definition.code)
        pinned = 0 if preference and preference.pinned else 1
        order = preference.display_order if preference and preference.display_order is not None else 10_000
        return (pinned, order, definition.calendar_priority * -1, definition.display_name)

    return sorted(definitions, key=key)


def resolve_tracker_settings(settings: TrackerSettings) -> TrackerSettingsValidationResult:
    """Validate settings and resolve them into an active tracker catalog."""
    registry = tracker_registry()
    packs = {pack.code: pack for pack in tracker_packs()}
    errors: list[str] = []
    warnings: list[str] = []

    unknown_packs = sorted(set(settings.enabled_pack_codes) - set(packs))
    errors.extend(f"unknown_pack_code:{code}" for code in unknown_packs)

    known_tracker_codes = set(registry)
    disabled_codes = set(settings.disabled_tracker_codes)
    unknown_disabled = sorted(disabled_codes - known_tracker_codes)
    errors.extend(f"unknown_disabled_tracker_code:{code}" for code in unknown_disabled)

    preferences_by_code: dict[str, TrackerPreference] = {}
    for preference in settings.tracker_preferences:
        if preference.tracker_code not in registry:
            errors.append(f"unknown_preference_tracker_code:{preference.tracker_code}")
            continue
        if preference.tracker_code in preferences_by_code:
            errors.append(f"duplicate_tracker_preference:{preference.tracker_code}")
            continue
        preferences_by_code[preference.tracker_code] = preference

    if errors:
        return TrackerSettingsValidationResult(ok=False, errors=errors, warnings=warnings, active_catalog=None)

    active_codes: set[str] = set()
    for pack_code in settings.enabled_pack_codes:
        active_codes.update(packs[pack_code].tracker_codes)

    for preference in preferences_by_code.values():
        if preference.enabled:
            active_codes.add(preference.tracker_code)
        else:
            disabled_codes.add(preference.tracker_code)

    active_codes -= disabled_codes
    definitions = _ordered_definitions([registry[code] for code in active_codes], preferences_by_code)

    if not active_codes:
        warnings.append("no_active_trackers")
    if "base_symptoms" not in settings.enabled_pack_codes:
        warnings.append("base_symptoms_pack_not_enabled")

    catalog = ActiveTrackerCatalog(
        subject_id=settings.subject_id,
        settings_schema_version=settings.schema_version,
        enabled_pack_codes=settings.enabled_pack_codes,
        tracker_definitions=definitions,
        tracker_preferences=list(preferences_by_code.values()),
        warnings=warnings,
    )
    return TrackerSettingsValidationResult(ok=True, errors=[], warnings=warnings, active_catalog=catalog)
