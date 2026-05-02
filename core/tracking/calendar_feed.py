"""Calendar feed assembly for Flutter-facing contracts."""

from __future__ import annotations

from datetime import date, timedelta

from core.contracts import CalendarAnnotation, CalendarDay, CalendarFeed, CalendarRange, CycleProjection


def _dates_between(start_date: date, end_date: date):
    current = start_date
    while current <= end_date:
        yield current
        current += timedelta(days=1)


def build_calendar_feed(
    *,
    subject_id: str,
    start_date: date,
    end_date: date,
    annotations: list[CalendarAnnotation] | None = None,
    cycle_projections: list[CycleProjection] | None = None,
) -> CalendarFeed:
    """Group contract annotations by day without choosing UI layout, color, or icons."""
    calendar_range = CalendarRange(start_date=start_date, end_date=end_date)
    annotations = annotations or []
    cycle_projections = cycle_projections or []

    by_day: dict[date, list[CalendarAnnotation]] = {day: [] for day in _dates_between(start_date, end_date)}
    for annotation in annotations:
        if annotation.subject_id != subject_id:
            continue
        annotation_end = annotation.end_date or annotation.date
        for day in _dates_between(max(annotation.date, start_date), min(annotation_end, end_date)):
            by_day.setdefault(day, []).append(annotation)

    states_by_day = {}
    for projection in cycle_projections:
        if projection.subject_id != subject_id or projection.started_on is None:
            continue
        projection_end = projection.ended_on or end_date
        for day in _dates_between(max(projection.started_on, start_date), min(projection_end, end_date)):
            states_by_day[day] = projection.state

    days = [
        CalendarDay(
            date=day,
            annotations=sorted(by_day.get(day, []), key=lambda item: item.priority, reverse=True),
            cycle_state=states_by_day.get(day),
        )
        for day in _dates_between(start_date, end_date)
    ]
    return CalendarFeed(subject_id=subject_id, range=calendar_range, days=days)
