"""Atlas temporal semantics for calendar-facing annotations."""

from core.contracts import CalendarAnnotation, ObservationEvent, TrackerDefinition


def observation_calendar_date(event: ObservationEvent):
    """Return the local calendar date Atlas should use for an observation."""
    return event.observed_on or event.observed_at.date()


def observation_to_calendar_annotation(
    event: ObservationEvent,
    definition: TrackerDefinition,
) -> CalendarAnnotation | None:
    """Map a universal observation event to a calendar annotation contract."""

    if definition.calendar_layer == "none":
        return None
    return CalendarAnnotation(
        id=f"calendar-{event.id}",
        subject_id=event.subject_id,
        source_type="observation",
        source_id=event.id,
        date=observation_calendar_date(event),
        end_date=event.ended_at.date() if event.ended_at else None,
        layer=definition.calendar_layer,  # type: ignore[arg-type]
        label=definition.display_name,
        tracker_code=event.tracker_code,
        value=event.value,
        priority=definition.calendar_priority,
    )
