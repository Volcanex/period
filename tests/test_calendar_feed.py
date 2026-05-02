from datetime import UTC, date, datetime

from core.contracts import CalendarAnnotation, CycleProjection, CycleState, ObservationEvent
from core.tracking import build_calendar_feed, observation_to_calendar_annotation, tracker_registry


def test_calendar_feed_groups_range_annotations_without_ui_decisions():
    registry = tracker_registry()
    event = ObservationEvent(
        id="obs-bleed-range-1",
        subject_id="subject-1",
        tracker_code="period_bleeding",
        observed_at=datetime(2026, 5, 2, 8, 0, tzinfo=UTC),
        ended_at=datetime(2026, 5, 4, 8, 0, tzinfo=UTC),
        source="user_entered",
        value="medium",
    )
    annotation = observation_to_calendar_annotation(event, registry[event.tracker_code])
    projection = CycleProjection(
        id="cycle-1",
        subject_id="subject-1",
        cycle_index=4,
        state=CycleState.ongoing,
        started_on=date(2026, 5, 2),
        generated_at=datetime(2026, 5, 2, 9, 0, tzinfo=UTC),
        algorithm_version="period-core-local-v1",
        confidence=0.7,
    )

    feed = build_calendar_feed(
        subject_id="subject-1",
        start_date=date(2026, 5, 1),
        end_date=date(2026, 5, 5),
        annotations=[annotation],
        cycle_projections=[projection],
    )

    assert len(feed.days) == 5
    by_date = {day.date: day for day in feed.days}
    assert by_date[date(2026, 5, 1)].annotations == []
    assert by_date[date(2026, 5, 2)].annotations[0].layer == "bleeding"
    assert by_date[date(2026, 5, 4)].annotations[0].source_id == "obs-bleed-range-1"
    assert by_date[date(2026, 5, 5)].cycle_state == CycleState.ongoing
    assert not hasattr(feed.days[1], "color")
    assert not hasattr(feed.days[1], "icon")


def test_calendar_feed_ignores_annotations_for_other_subjects():
    annotation = CalendarAnnotation(
        id="cal-other-1",
        subject_id="other-subject",
        source_type="observation",
        source_id="obs-other-1",
        date=date(2026, 5, 2),
        layer="symptom",
        label="Cramps",
        tracker_code="cramps",
        value="mild",
    )
    feed = build_calendar_feed(
        subject_id="subject-1",
        start_date=date(2026, 5, 2),
        end_date=date(2026, 5, 2),
        annotations=[annotation],
    )
    assert feed.days[0].annotations == []
