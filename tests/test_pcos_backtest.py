import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

from core.analyzers import (
    backtest_pcos_cases,
    evaluate_pcos,
    load_pcos_backtest_fixture,
    pcos_backtest_summary_to_dict,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FIXED_EVAL = datetime(2026, 5, 11, tzinfo=UTC)


def _fold_summary_with_fixed_anchor():
    cases = load_pcos_backtest_fixture()
    matches = 0
    statuses: dict[str, int] = {}
    for case in cases:
        result = evaluate_pcos(
            case.subject_id,
            list(case.observations),
            years_since_menarche=case.years_since_menarche,
            evaluated_at=FIXED_EVAL,
        )
        statuses[result.status] = statuses.get(result.status, 0) + 1
        if result.status == case.expected_status:
            matches += 1
    return cases, matches, statuses


def test_pcos_backtest_fixture_matches_expected_statuses_with_fixed_anchor():
    cases, matches, statuses = _fold_summary_with_fixed_anchor()
    assert matches == len(cases)
    assert statuses["features_present"] >= 1
    assert statuses["features_partial"] >= 1
    assert statuses["features_absent"] >= 1
    assert statuses["suppressed"] >= 1
    assert statuses["insufficient_data"] >= 1


def test_pcos_backtest_summary_is_stably_serializable():
    summary = backtest_pcos_cases(load_pcos_backtest_fixture())
    payload = pcos_backtest_summary_to_dict(summary)
    assert payload["analyzer_code"] == "pcos_feature_pattern_v1"
    assert payload["fold_count"] == len(summary.folds)
    assert 0 <= payload["exact_match_rate"] <= 1


def test_pcos_backtest_script_outputs_stable_json():
    result = subprocess.run(
        [sys.executable, "scripts/pcos_backtest.py"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["analyzer_code"] == "pcos_feature_pattern_v1"
    assert report["fold_count"] >= 8
    assert report["exact_match_rate"] == 1.0
