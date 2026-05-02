from datetime import UTC, date, datetime, timedelta

from core.contracts import CalendarAnnotation, ObservationEvent
from core.tracking import observation_calendar_date, observation_to_calendar_annotation, tracker_registry


def test_observation_calendar_date_prefers_explicit_local_date():
    event = ObservationEvent(
        id="obs-night-1",
        subject_id="subject-1",
        tracker_code="cramps",
        observed_at=datetime(2026, 5, 2, 23, 30, tzinfo=UTC),
        observed_on=date(2026, 5, 3),
        source="user_entered",
        value="mild",
    )
    assert observation_calendar_date(event) == date(2026, 5, 3)


def test_observation_to_calendar_annotation_uses_tracker_temporal_metadata():
    registry = tracker_registry()
    event = ObservationEvent(
        id="obs-bleeding-1",
        subject_id="subject-1",
        tracker_code="period_bleeding",
        observed_at=datetime(2026, 5, 2, 8, 0, tzinfo=UTC),
        ended_at=datetime(2026, 5, 4, 8, 0, tzinfo=UTC),
        source="user_entered",
        value="medium",
    )
    annotation = observation_to_calendar_annotation(event, registry[event.tracker_code])
    assert isinstance(annotation, CalendarAnnotation)
    assert annotation.date == date(2026, 5, 2)
    assert annotation.end_date == date(2026, 5, 4)
    assert annotation.layer == "bleeding"
    assert annotation.priority == 95
    assert annotation.tracker_code == "period_bleeding"


def test_calendar_annotation_is_a_contract_not_ui_layout():
    registry = tracker_registry()
    event = ObservationEvent(
        id="obs-temp-2",
        subject_id="subject-1",
        tracker_code="basal_body_temperature",
        observed_at=datetime.now(UTC) - timedelta(days=1),
        source="imported",
        value=36.4,
        unit="celsius",
    )
    annotation = observation_to_calendar_annotation(event, registry[event.tracker_code])
    assert annotation.layer == "temperature"
    assert not hasattr(annotation, "color")
    assert not hasattr(annotation, "icon")
