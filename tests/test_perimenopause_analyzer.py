from datetime import UTC, date, datetime, timedelta

import pytest

from core.analyzers import (
    PERIMENOPAUSE_ANALYZER_CODE,
    PERIMENOPAUSE_ANALYZER_VERSION,
    evaluate_perimenopause,
)
from core.contracts import ObservationEvent, PerimenopauseEvaluationRequest
from server import app
from tests.http_client import SyncASGIClient

EVAL_ANCHOR = datetime(2027, 1, 1, tzinfo=UTC)
ANCHOR_DATE = EVAL_ANCHOR.date()


def _event(index: int, day: str, tracker_code: str, value: object) -> ObservationEvent:
    observed_at = datetime.fromisoformat(f"{day}T12:00:00+00:00")
    return ObservationEvent(
        id=f"obs-{index}",
        subject_id="subject-perimeno-1",
        tracker_code=tracker_code,
        observed_at=observed_at,
        observed_on=observed_at.date(),
        source="user_entered",
        value=value,
    )


def _bleed_run(start_index: int, onset: date, days: int = 4) -> list[ObservationEvent]:
    return [
        _event(start_index + offset, (onset + timedelta(days=offset)).isoformat(), "period_bleeding", "medium")
        for offset in range(days)
    ]


def _onsets(cycle_lengths: list[int]) -> list[date]:
    cur = ANCHOR_DATE - timedelta(days=sum(cycle_lengths))
    out: list[date] = []
    for length in cycle_lengths:
        out.append(cur)
        cur = cur + timedelta(days=length)
    return out


def _build_bleeding(cycle_lengths: list[int], start: int = 1) -> list[ObservationEvent]:
    obs: list[ObservationEvent] = []
    idx = start
    for onset in _onsets(cycle_lengths):
        obs.extend(_bleed_run(idx, onset))
        idx += 4
    return obs


def test_reproductive_stage_minus_3b_with_regular_cycles():
    obs = _build_bleeding([28] * 12)
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=32, evaluated_at=EVAL_ANCHOR)
    assert result.analyzer_code == PERIMENOPAUSE_ANALYZER_CODE
    assert result.analyzer_version == PERIMENOPAUSE_ANALYZER_VERSION
    assert result.straw_stage == "minus_3b"
    assert result.status == "reproductive"
    assert result.confidence == "high"


def test_late_reproductive_minus_3a_when_pattern_change_reported():
    obs = _build_bleeding([29, 28, 27, 26, 26, 25, 24, 24, 25, 24])
    obs.append(_event(99, (ANCHOR_DATE - timedelta(days=30)).isoformat(), "cycle_pattern_change", "yes"))
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=42, evaluated_at=EVAL_ANCHOR)
    assert result.straw_stage == "minus_3a"
    assert result.status == "reproductive"


def test_early_transition_minus_2_persistent_seven_day_variability():
    obs = _build_bleeding([28, 29, 38, 30, 41, 33, 44, 32, 42, 35])
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=46, evaluated_at=EVAL_ANCHOR)
    assert result.straw_stage == "minus_2"
    assert result.status == "early_transition"
    assert result.cycle_signal.persistent_seven_day_variability is True


def test_late_transition_minus_1_when_amenorrhea_60_plus():
    obs = _build_bleeding([30, 30, 30, 95, 35, 35])
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=49, evaluated_at=EVAL_ANCHOR)
    assert result.straw_stage == "minus_1"
    assert result.status == "late_transition"
    assert result.cycle_signal.amenorrhea_60_plus_days_observed is True


def test_postmenopause_plus_1a_when_amenorrhea_12_plus_months():
    last_bleed = ANCHOR_DATE - timedelta(days=14 * 30)
    obs = _bleed_run(1, last_bleed - timedelta(days=60))
    obs.extend(_bleed_run(20, last_bleed))
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=52, evaluated_at=EVAL_ANCHOR, evaluation_window_days=540)
    assert result.straw_stage == "plus_1a"
    assert result.status == "postmenopause"
    assert result.fmp_candidate_date == last_bleed
    assert result.months_since_last_bleed and result.months_since_last_bleed >= 12


def test_known_fmp_date_drives_plus_1b_without_bleeding_history():
    known_fmp = ANCHOR_DATE - timedelta(days=30 * 30)
    result = evaluate_perimenopause(
        "subject-perimeno-1",
        [],
        chronological_age=54,
        known_fmp_date=known_fmp,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result.straw_stage == "plus_1b"
    assert result.status == "postmenopause"
    assert result.fmp_candidate_date == known_fmp


def test_known_fmp_date_drives_plus_2_after_eight_years():
    known_fmp = ANCHOR_DATE - timedelta(days=100 * 30)
    result = evaluate_perimenopause(
        "subject-perimeno-1",
        [],
        chronological_age=61,
        known_fmp_date=known_fmp,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result.straw_stage == "plus_2"
    assert result.status == "postmenopause"


def test_combined_oral_contraceptive_suppresses_evaluation():
    obs = _build_bleeding([28] * 6)
    obs.append(_event(99, (ANCHOR_DATE - timedelta(days=200)).isoformat(), "contraception_use", "pill"))
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=47, evaluated_at=EVAL_ANCHOR)
    assert result.status == "suppressed"
    assert "combined_oral_contraceptive" in result.suppressors
    assert result.straw_stage == "indeterminate"


def test_post_hysterectomy_is_inapplicable():
    obs = [
        _event(1, (ANCHOR_DATE - timedelta(days=120)).isoformat(), "hot_flashes", "severe"),
        _event(2, (ANCHOR_DATE - timedelta(days=90)).isoformat(), "hot_flashes", "moderate"),
    ]
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=50, post_hysterectomy=True, evaluated_at=EVAL_ANCHOR)
    assert result.status == "inapplicable"
    assert "post_hysterectomy_or_ablation" in result.inapplicability_flags


def test_under_40_late_transition_flags_poi_differential():
    obs = _build_bleeding([30, 30, 90, 30])
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=35, evaluated_at=EVAL_ANCHOR)
    assert result.straw_stage == "minus_1"
    assert any("premature_ovarian_insufficiency" in reminder for reminder in result.differential_reminders)
    assert any("primary ovarian insufficiency" in action.lower() for action in result.recommended_actions)


def test_indeterminate_when_only_one_recent_bleed():
    obs = _bleed_run(1, ANCHOR_DATE - timedelta(days=20))
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=44, evaluated_at=EVAL_ANCHOR)
    assert result.straw_stage == "indeterminate"
    assert result.status == "indeterminate"


def test_symptom_signal_accumulates_severity_persistence():
    obs = _build_bleeding([28] * 6)
    obs.extend([
        _event(101, (ANCHOR_DATE - timedelta(days=120)).isoformat(), "hot_flashes", "severe"),
        _event(102, (ANCHOR_DATE - timedelta(days=100)).isoformat(), "hot_flashes", "moderate"),
        _event(103, (ANCHOR_DATE - timedelta(days=80)).isoformat(), "vaginal_dryness", "moderate"),
        _event(104, (ANCHOR_DATE - timedelta(days=60)).isoformat(), "vaginal_dryness", "moderate"),
    ])
    result = evaluate_perimenopause("subject-perimeno-1", obs, chronological_age=50, evaluated_at=EVAL_ANCHOR)
    assert result.symptom_signal.hot_flashes_persistent is True
    assert result.symptom_signal.vaginal_dryness_persistent is True
    assert result.symptom_signal.vasomotor_present is True
    assert result.symptom_signal.urogenital_atrophy_present is True


def test_perimenopause_endpoint_round_trip():
    client = SyncASGIClient(app)
    obs = _build_bleeding([28, 29, 38, 30, 41, 33, 44, 32])
    payload = PerimenopauseEvaluationRequest(
        subject_id="subject-perimeno-1",
        observations=obs,
        chronological_age=46,
        evaluated_at=EVAL_ANCHOR,
    ).model_dump(mode="json")
    response = client.post("/api/v1/analyzers/perimenopause/evaluate", json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["analyzer_code"] == PERIMENOPAUSE_ANALYZER_CODE
    assert body["analyzer_version"] == PERIMENOPAUSE_ANALYZER_VERSION
    assert body["status"] == "early_transition"
    assert body["straw_stage"] == "minus_2"
    assert body["evidence"]
    assert body["differential_reminders"]


@pytest.mark.parametrize(
    "post_hysterectomy, expected_status",
    [(True, "inapplicable"), (False, "early_transition")],
)
def test_post_hysterectomy_flag_short_circuits_staging(post_hysterectomy, expected_status):
    obs = _build_bleeding([28, 29, 38, 30, 41, 33, 44, 32])
    result = evaluate_perimenopause(
        "subject-perimeno-1",
        obs,
        chronological_age=46,
        post_hysterectomy=post_hysterectomy,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result.status == expected_status
