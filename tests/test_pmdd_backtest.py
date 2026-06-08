import json
import subprocess
import sys
from pathlib import Path

from core.analyzers import backtest_pmdd_cases, load_pmdd_backtest_fixture, pmdd_backtest_summary_to_dict

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_pmdd_backtest_fixture_matches_expected_statuses():
    cases = load_pmdd_backtest_fixture()
    summary = backtest_pmdd_cases(cases)

    assert summary.fold_count == 4
    assert summary.exact_match_rate == 1.0
    assert {fold.predicted_status for fold in summary.folds} == {
        "pattern",
        "activation",
        "suppressed",
        "insufficient_data",
    }


def test_pmdd_backtest_summary_is_stably_serializable():
    summary = backtest_pmdd_cases(load_pmdd_backtest_fixture())
    payload = pmdd_backtest_summary_to_dict(summary)

    assert payload["analyzer_code"] == "pmdd_pattern_v1"
    assert payload["fold_count"] == 4
    assert payload["exact_match_rate"] == 1.0
    assert payload["expected_status_counts"]["pattern"] == 1
    assert payload["predicted_status_counts"]["suppressed"] == 1


def test_pmdd_backtest_script_outputs_stable_json():
    result = subprocess.run(
        [sys.executable, "scripts/pmdd_backtest.py"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["analyzer_code"] == "pmdd_pattern_v1"
    assert report["fold_count"] == 4
    assert report["exact_match_rate"] == 1.0
