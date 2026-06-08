from datetime import UTC, date, datetime, timedelta

import pytest

from core.analyzers import PCOS_ANALYZER_CODE, PCOS_ANALYZER_VERSION, evaluate_pcos
from core.contracts import ObservationEvent, PcosEvaluationRequest
from server import app
from tests.http_client import SyncASGIClient

EVAL_ANCHOR = datetime(2026, 5, 11, tzinfo=UTC)


def _event(index: int, day: str, tracker_code: str, value: object) -> ObservationEvent:
    observed_at = datetime.fromisoformat(f"{day}T12:00:00+00:00")
    return ObservationEvent(
        id=f"obs-{index}",
        subject_id="subject-pcos-1",
        tracker_code=tracker_code,
        observed_at=observed_at,
        observed_on=observed_at.date(),
        source="user_entered",
        value=value,
    )


def _bleed_run(start_index: int, onset: str, days: int = 4) -> list[ObservationEvent]:
    base = date.fromisoformat(onset)
    return [
        _event(start_index + offset, (base + timedelta(days=offset)).isoformat(), "period_bleeding", "medium")
        for offset in range(days)
    ]


def test_features_present_in_adult_with_persistent_features():
    observations = [
        *_bleed_run(1, "2026-01-04"),
        *_bleed_run(5, "2026-02-15"),  # 42 days
        *_bleed_run(9, "2026-04-03"),  # 47 days
        _event(20, "2026-03-10", "acne_severity", "severe"),
        _event(21, "2026-03-22", "acne_severity", "moderate"),
        _event(22, "2026-04-01", "hair_growth", "moderate"),
        _event(23, "2026-04-15", "hair_growth", "moderate"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=12,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.analyzer_code == PCOS_ANALYZER_CODE
    assert result.analyzer_version == PCOS_ANALYZER_VERSION
    assert result.status == "features_present"
    assert result.age_group_used == "adult"
    assert result.rotterdam_self_report_feature_count == 2
    assert result.cycle_irregularity.classification == "irregular"
    assert result.hyperandrogenism.meets_hyperandrogenism_rule is True
    assert result.suppressors == []
    assert result.evidence  # at least one citation


def test_features_partial_when_only_irregularity_in_adult_flags_pcom_pathway():
    observations = [
        *_bleed_run(1, "2026-01-06"),
        *_bleed_run(5, "2026-02-19"),  # 44 days
        *_bleed_run(9, "2026-04-11"),  # 51 days
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=10,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.status == "features_partial"
    assert result.rotterdam_self_report_feature_count == 1
    assert result.meets_irregularity_rule is True
    assert result.meets_hyperandrogenism_rule is False
    assert result.pcom_assessment_could_resolve is True
    assert any("pelvic ultrasound or AMH" in action for action in result.recommended_actions)


def test_adolescent_pubertal_year_suppresses_cycle_classification():
    observations = [
        *_bleed_run(1, "2026-01-10"),
        *_bleed_run(5, "2026-03-06"),  # 55 days
        _event(20, "2026-03-15", "acne_severity", "severe"),
        _event(21, "2026-03-25", "acne_severity", "severe"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=0.5,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.age_group_used == "adolescent_pubertal"
    assert result.cycle_irregularity.classification == "pubertal_transition"
    assert result.cycle_irregularity.meets_irregularity_rule is False
    # Only the hyperandrogenism feature is interpretable within year 1 post-menarche.
    assert result.status == "features_partial"
    assert result.adolescent_both_features_required is True


def test_adolescent_post_menarche_requires_both_features():
    observations_one_feature = [
        *_bleed_run(1, "2026-01-08"),
        *_bleed_run(5, "2026-03-07"),  # 58-day cycle, irregular for 1-3y post-menarche
    ]
    result_one = evaluate_pcos(
        "subject-pcos-1",
        observations_one_feature,
        years_since_menarche=2.0,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result_one.age_group_used == "adolescent_post"
    assert result_one.status == "features_partial"
    assert result_one.pcom_assessment_could_resolve is False  # adolescents do not use US/AMH

    observations_both = observations_one_feature + [
        _event(20, "2026-03-12", "acne_severity", "severe"),
        _event(21, "2026-03-25", "acne_severity", "moderate"),
    ]
    result_both = evaluate_pcos(
        "subject-pcos-1",
        observations_both,
        years_since_menarche=2.0,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result_both.status == "features_present"
    assert result_both.meets_irregularity_rule is True
    assert result_both.meets_hyperandrogenism_rule is True


def test_combined_oral_contraceptive_suppresses_evaluation():
    observations = [
        *_bleed_run(1, "2026-01-05"),
        *_bleed_run(5, "2026-02-14"),
        _event(20, "2026-02-01", "acne_severity", "severe"),
        _event(21, "2026-02-12", "acne_severity", "moderate"),
        _event(22, "2026-01-01", "contraception_use", "pill"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=11,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.status == "suppressed"
    assert "combined_oral_contraceptive" in result.suppressors
    assert result.confidence == "low"
    assert any("washout" in action for action in result.recommended_actions)


def test_pregnancy_suppresses_evaluation():
    observations = [
        *_bleed_run(1, "2026-01-07"),
        _event(20, "2026-04-01", "pregnancy_test", "positive"),
        _event(21, "2026-02-10", "acne_severity", "moderate"),
        _event(22, "2026-02-22", "acne_severity", "moderate"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=9,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.status == "suppressed"
    assert "pregnancy" in result.suppressors


def test_features_absent_with_clean_adult_cycles():
    observations = [
        *_bleed_run(1, "2026-01-05"),
        *_bleed_run(5, "2026-02-02"),
        *_bleed_run(9, "2026-03-02"),
        *_bleed_run(13, "2026-03-31"),
        *_bleed_run(17, "2026-04-28"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=14,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.status == "features_absent"
    assert result.cycle_irregularity.classification == "regular"
    assert result.rotterdam_self_report_feature_count == 0


def test_long_single_cycle_triggers_irregularity_at_any_age():
    observations = [
        *_bleed_run(1, "2025-12-01"),
        *_bleed_run(5, "2026-03-15"),  # 104-day single cycle
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=20,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.cycle_irregularity.meets_irregularity_rule is True
    assert any(">90 days" in result.cycle_irregularity.rationale for _ in [0])


def test_self_report_fallback_when_bleeding_history_missing():
    observations = [
        _event(1, "2026-05-01", "cycle_regularity", "infrequent"),
        _event(2, "2026-03-05", "hair_growth", "severe"),
        _event(3, "2026-03-25", "hair_growth", "moderate"),
        _event(4, "2026-04-15", "hair_growth", "moderate"),
    ]

    result = evaluate_pcos(
        "subject-pcos-1",
        observations,
        years_since_menarche=15,
        evaluated_at=EVAL_ANCHOR,
    )

    assert result.cycle_irregularity.fallback_to_self_report is True
    assert result.status == "features_present"


def test_insufficient_data_returns_low_information_status():
    result = evaluate_pcos(
        "subject-pcos-1",
        [],
        years_since_menarche=10,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result.status == "insufficient_data"
    assert result.rotterdam_self_report_feature_count == 0
    assert result.confidence == "none"


@pytest.mark.parametrize(
    "years_since_menarche, expected_group",
    [
        (None, "unknown"),
        (0.5, "adolescent_pubertal"),
        (2.0, "adolescent_post"),
        (12.0, "adult"),
    ],
)
def test_age_classification_maps_years_since_menarche(years_since_menarche, expected_group):
    result = evaluate_pcos(
        "subject-pcos-1",
        [],
        years_since_menarche=years_since_menarche,
        evaluated_at=EVAL_ANCHOR,
    )
    assert result.age_group_used == expected_group


def test_pcos_endpoint_round_trip():
    client = SyncASGIClient(app)
    observations = [
        *_bleed_run(1, "2026-01-04"),
        *_bleed_run(5, "2026-02-15"),
        *_bleed_run(9, "2026-04-03"),
        _event(20, "2026-03-10", "acne_severity", "severe"),
        _event(21, "2026-03-22", "acne_severity", "moderate"),
    ]

    payload = PcosEvaluationRequest(
        subject_id="subject-pcos-1",
        observations=observations,
        years_since_menarche=12,
        evaluated_at=EVAL_ANCHOR,
    ).model_dump(mode="json")

    response = client.post("/api/v1/analyzers/pcos/evaluate", json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["analyzer_code"] == PCOS_ANALYZER_CODE
    assert body["analyzer_version"] == PCOS_ANALYZER_VERSION
    assert body["status"] in {"features_present", "features_partial"}
    assert body["age_group_used"] == "adult"
    assert body["differential_reminders"]  # mimics list always included
    assert body["evidence"]
