#!/usr/bin/env python3
"""Run the synthetic perimenopause STRAW+10 backtest and print stable JSON.

The fixture lives at tests/data/perimenopause_backtest_cases.json (built by
scripts/build_perimenopause_backtest_cases.py). Evaluation anchor is pinned at
2027-01-01 so amenorrhea/FMP windows are deterministic across runs.
"""

from __future__ import annotations

import json
import sys
from datetime import UTC, datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.analyzers import (  # noqa: E402
    PerimenopauseBacktestFold,
    PerimenopauseBacktestSummary,
    evaluate_perimenopause,
    load_perimenopause_backtest_fixture,
    perimenopause_backtest_summary_to_dict,
)

FIXED_EVALUATION_TIME = datetime(2027, 1, 1, tzinfo=UTC)


def main() -> int:
    cases = load_perimenopause_backtest_fixture()
    folds: list[PerimenopauseBacktestFold] = []
    for case in cases:
        result = evaluate_perimenopause(
            case.subject_id,
            list(case.observations),
            chronological_age=case.chronological_age,
            post_hysterectomy=case.post_hysterectomy,
            known_fmp_date=case.known_fmp_date,
            evaluated_at=FIXED_EVALUATION_TIME,
        )
        folds.append(
            PerimenopauseBacktestFold(
                case_id=case.case_id,
                expected_status=case.expected_status,
                predicted_status=result.status,
                expected_stage=case.expected_stage,
                predicted_stage=result.straw_stage,
                status_match=result.status == case.expected_status,
                stage_match=result.straw_stage == case.expected_stage,
                confidence=result.confidence,
            )
        )
    summary = PerimenopauseBacktestSummary(
        fold_count=len(folds),
        exact_status_match_rate=sum(1 for fold in folds if fold.status_match) / len(folds) if folds else 0.0,
        exact_stage_match_rate=sum(1 for fold in folds if fold.stage_match) / len(folds) if folds else 0.0,
        folds=tuple(folds),
    )
    print(json.dumps(perimenopause_backtest_summary_to_dict(summary), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
