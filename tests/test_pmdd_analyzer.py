from datetime import UTC, datetime

from core.analyzers import PMDD_ANALYZER_CODE, PMDD_ANALYZER_VERSION, evaluate_pmdd
from core.contracts import ObservationEvent, PmddEvaluationRequest
from server import app
from tests.http_client import SyncASGIClient


def _event(index: int, day: str, tracker_code: str, value: object) -> ObservationEvent:
    observed_at = datetime.fromisoformat(f"{day}T12:00:00+00:00")
    return ObservationEvent(
        id=f"obs-{index}",
        subject_id="subject-local-1",
        tracker_code=tracker_code,
        observed_at=observed_at,
        observed_on=observed_at.date(),
        source="user_entered",
        value=value,
    )


def test_pmdd_analyzer_detects_repeated_rich_pattern():
    observations = [
        _event(1, "2026-03-01", "period_bleeding", "light"),
        _event(2, "2026-02-22", "drsp_mood_swings", 5),
        _event(3, "2026-02-23", "drsp_mood_swings", 5),
        _event(4, "2026-02-24", "drsp_hopelessness", 5),
        _event(5, "2026-02-25", "drsp_hopelessness", 5),
        _event(6, "2026-02-26", "drsp_less_interest", 4),
        _event(7, "2026-02-27", "drsp_less_interest", 4),
        _event(8, "2026-02-27", "drsp_difficulty_concentrating", 4),
        _event(9, "2026-02-28", "drsp_difficulty_concentrating", 4),
        _event(10, "2026-02-27", "drsp_overwhelmed", 4),
        _event(11, "2026-02-28", "drsp_overwhelmed", 4),
        _event(12, "2026-02-24", "drsp_productivity_impairment", 5),
        _event(13, "2026-02-25", "drsp_productivity_impairment", 5),
        _event(14, "2026-03-05", "drsp_mood_swings", 1),
        _event(15, "2026-03-06", "drsp_mood_swings", 1),
        _event(16, "2026-03-07", "drsp_hopelessness", 1),
        _event(17, "2026-03-08", "drsp_hopelessness", 1),
        _event(18, "2026-03-05", "drsp_less_interest", 1),
        _event(19, "2026-03-06", "drsp_difficulty_concentrating", 1),
        _event(20, "2026-03-07", "drsp_overwhelmed", 1),
        _event(21, "2026-03-05", "drsp_productivity_impairment", 1),
        _event(22, "2026-03-29", "period_bleeding", "light"),
        _event(23, "2026-03-22", "drsp_mood_swings", 5),
        _event(24, "2026-03-23", "drsp_mood_swings", 5),
        _event(25, "2026-03-24", "drsp_hopelessness", 5),
        _event(26, "2026-03-25", "drsp_hopelessness", 5),
        _event(27, "2026-03-26", "drsp_less_interest", 4),
        _event(28, "2026-03-27", "drsp_less_interest", 4),
        _event(29, "2026-03-27", "drsp_difficulty_concentrating", 4),
        _event(30, "2026-03-28", "drsp_difficulty_concentrating", 4),
        _event(31, "2026-03-27", "drsp_overwhelmed", 4),
        _event(32, "2026-03-28", "drsp_overwhelmed", 4),
        _event(33, "2026-03-24", "drsp_productivity_impairment", 5),
        _event(34, "2026-03-25", "drsp_productivity_impairment", 5),
        _event(35, "2026-04-02", "drsp_mood_swings", 1),
        _event(36, "2026-04-03", "drsp_mood_swings", 1),
        _event(37, "2026-04-04", "drsp_hopelessness", 1),
        _event(38, "2026-04-08", "drsp_hopelessness", 1),
        _event(39, "2026-04-02", "drsp_less_interest", 1),
        _event(40, "2026-04-03", "drsp_difficulty_concentrating", 1),
        _event(41, "2026-04-04", "drsp_overwhelmed", 1),
        _event(42, "2026-04-02", "drsp_productivity_impairment", 1),
    ]

    result = evaluate_pmdd("subject-local-1", observations)

    assert result.analyzer_code == PMDD_ANALYZER_CODE
    assert result.analyzer_version == PMDD_ANALYZER_VERSION
    assert result.status == "pattern"
    assert result.confidence == "moderate"
    assert result.supporting_cycle_count == 2
    assert result.meets_chronicity_rule is True
    assert result.cycle_evaluations[0].core_symptom_rule_met is True
    assert result.cycle_evaluations[0].total_symptom_rule_met is True
    assert result.cycle_evaluations[0].impairment_rule_met is True
    assert result.rich_pattern_logged is True


def test_pmdd_analyzer_suppresses_with_confounding_context():
    observations = [
        _event(1, "2026-03-01", "period_bleeding", "light"),
        _event(2, "2026-02-22", "drsp_anxiety_tension", 5),
        _event(3, "2026-02-23", "drsp_anxiety_tension", 5),
        _event(4, "2026-02-24", "drsp_depressed_mood", 4),
        _event(5, "2026-02-25", "drsp_depressed_mood", 4),
        _event(6, "2026-03-05", "drsp_anxiety_tension", 1),
        _event(7, "2026-03-06", "drsp_anxiety_tension", 1),
        _event(8, "2026-03-07", "drsp_depressed_mood", 1),
        _event(9, "2026-03-08", "drsp_depressed_mood", 1),
        _event(10, "2026-03-09", "drsp_productivity_impairment", 1),
        _event(10, "2026-03-11", "postpartum_status", True),
        _event(11, "2026-03-12", "drsp_productivity_impairment", 1),
    ]

    result = evaluate_pmdd("subject-local-1", observations)

    assert result.status == "suppressed"
    assert result.confidence == "low"
    assert "postpartum" in result.suppressors


def test_pmdd_endpoint_round_trip():
    client = SyncASGIClient(app)
    observations = [
        _event(1, "2026-03-01", "period_bleeding", "light"),
        _event(2, "2026-02-22", "drsp_anxiety_tension", 5),
        _event(3, "2026-02-23", "drsp_anxiety_tension", 5),
        _event(4, "2026-02-24", "drsp_depressed_mood", 4),
        _event(5, "2026-02-25", "drsp_depressed_mood", 4),
        _event(6, "2026-03-05", "drsp_anxiety_tension", 1),
        _event(7, "2026-03-06", "drsp_anxiety_tension", 1),
        _event(8, "2026-03-07", "drsp_depressed_mood", 1),
        _event(9, "2026-03-08", "drsp_depressed_mood", 1),
        _event(10, "2026-03-09", "drsp_productivity_impairment", 1),
        _event(11, "2026-03-29", "period_bleeding", "light"),
        _event(12, "2026-03-22", "drsp_anxiety_tension", 5),
        _event(13, "2026-03-23", "drsp_anxiety_tension", 5),
        _event(14, "2026-03-24", "drsp_depressed_mood", 4),
        _event(15, "2026-03-25", "drsp_depressed_mood", 4),
        _event(16, "2026-03-24", "drsp_productivity_impairment", 4),
        _event(17, "2026-03-25", "drsp_productivity_impairment", 4),
        _event(18, "2026-04-02", "drsp_anxiety_tension", 1),
        _event(19, "2026-04-03", "drsp_anxiety_tension", 1),
        _event(20, "2026-04-04", "drsp_depressed_mood", 1),
        _event(21, "2026-04-05", "drsp_depressed_mood", 1),
        _event(22, "2026-04-06", "drsp_productivity_impairment", 1),
        _event(23, "2026-04-09", "drsp_productivity_impairment", 1),
    ]

    response = client.post(
        "/api/v1/analyzers/pmdd/evaluate",
        json=PmddEvaluationRequest(subject_id="subject-local-1", observations=observations).model_dump(mode="json"),
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["analyzer_code"] == PMDD_ANALYZER_CODE
    assert payload["status"] == "activation"
    assert payload["subject_id"] == "subject-local-1"
