"""Atlas observation validation."""

from typing import Any

from core.contracts import ObservationEvent, ObservationValidationResult
from core.tracking.registry import tracker_registry


def _type_ok(value: Any, schema_type: str) -> bool:
    if schema_type == "boolean":
        return isinstance(value, bool)
    if schema_type == "string":
        return isinstance(value, str)
    if schema_type == "number":
        return isinstance(value, int | float) and not isinstance(value, bool)
    if schema_type == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    return True


def validate_observation_event(event: ObservationEvent) -> ObservationValidationResult:
    registry = tracker_registry()
    definition = registry.get(event.tracker_code)
    if definition is None:
        return ObservationValidationResult(ok=False, tracker_code=event.tracker_code, errors=["unknown_tracker_code"])

    errors: list[str] = []
    schema = definition.validation_schema
    schema_type = schema.get("type")
    if isinstance(schema_type, str) and not _type_ok(event.value, schema_type):
        errors.append("invalid_value_type")

    enum = schema.get("enum")
    if enum is not None and event.value not in enum:
        errors.append("value_not_allowed")

    minimum = schema.get("minimum")
    if minimum is not None and isinstance(event.value, int | float) and event.value < minimum:
        errors.append("value_below_minimum")

    maximum = schema.get("maximum")
    if maximum is not None and isinstance(event.value, int | float) and event.value > maximum:
        errors.append("value_above_maximum")

    max_length = schema.get("maxLength")
    if max_length is not None and isinstance(event.value, str) and len(event.value) > max_length:
        errors.append("value_too_long")

    if event.unit is not None and definition.unit is not None and event.unit != definition.unit:
        errors.append("unit_mismatch")

    return ObservationValidationResult(ok=not errors, tracker_code=event.tracker_code, errors=errors)
