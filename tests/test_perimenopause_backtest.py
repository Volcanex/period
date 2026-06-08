import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

from core.analyzers import (
    backtest_perimenopause_cases,
    evaluate_perimenopause,
    load_perimenopause_backtest_fixture,
    perimenopause_backtest_summary_to_dict,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FIXED_EVAL = datetime(2027, 1, 1, tzinfo=UTC)


def test_fixture_matches_expected_status_and_stage_with_fixed_anchor():
    cases = load_perimenopause_backtest_fixture()
    status_hits = 0
    stage_hits = 0
    statuses: dict[str, int] = {}
    stages: dict[str, int] = {}
    for case in cases:
        result = evaluate_perimenopause(
            case.subject_id,
            list(case.observations),
            chronological_age=case.chronological_age,
            post_hysterectomy=case.post_hysterectomy,
            known_fmp_date=case.known_fmp_date,
            evaluated_at=FIXED_EVAL,
        )
        statuses[result.status] = statuses.get(result.status, 0) + 1
        stages[result.straw_stage] = stages.get(result.straw_stage, 0) + 1
        if result.status == case.expected_status:
            status_hits += 1
        if result.straw_stage == case.expected_stage:
            stage_hits += 1
    assert status_hits == len(cases)
    assert stage_hits == len(cases)
    # All five status categories represented at least once.
    for required in {"reproductive", "early_transition", "late_transition", "postmenopause", "suppressed", "inapplicable", "indeterminate"}:
        assert required in statuses, f"missing status {required} in fixture: {statuses}"


def test_summary_dict_is_stable():
    summary = backtest_perimenopause_cases(load_perimenopause_backtest_fixture())
    payload = perimenopause_backtest_summary_to_dict(summary)
    assert payload["analyzer_code"] == "perimenopause_straw10_v1"
    assert payload["fold_count"] == len(summary.folds)
    assert 0 <= payload["exact_status_match_rate"] <= 1
    assert 0 <= payload["exact_stage_match_rate"] <= 1


def test_backtest_script_outputs_stable_json():
    result = subprocess.run(
        [sys.executable, "scripts/perimenopause_backtest.py"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["analyzer_code"] == "perimenopause_straw10_v1"
    assert report["fold_count"] >= 10
    assert report["exact_status_match_rate"] == 1.0
    assert report["exact_stage_match_rate"] == 1.0
