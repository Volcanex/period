#!/usr/bin/env python3
"""Run the synthetic PMDD backtest suite and print stable JSON."""

from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.analyzers import backtest_pmdd_cases, load_pmdd_backtest_fixture, pmdd_backtest_summary_to_dict  # noqa: E402


def main() -> int:
    cases = load_pmdd_backtest_fixture()
    summary = backtest_pmdd_cases(cases)
    print(json.dumps(pmdd_backtest_summary_to_dict(summary), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
