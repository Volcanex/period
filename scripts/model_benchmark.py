#!/usr/bin/env python3
"""Print a stable JSON benchmark report for the Period core model."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.model import benchmark_summary_to_dict, benchmark_train_validation_split, load_urteaga_cycle_lengths_npz

DEFAULT_DATASET = PROJECT_ROOT / "tests" / "data" / "urteaga_cycle_lengths.npz"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--max-subjects", type=int, default=1200)
    parser.add_argument("--calibration-subjects", type=int, default=400)
    parser.add_argument("--min-train-cycles", type=int, default=3)
    args = parser.parse_args()

    subjects = load_urteaga_cycle_lengths_npz(args.dataset, max_subjects=args.max_subjects)
    summary = benchmark_train_validation_split(
        subjects,
        calibration_subjects=args.calibration_subjects,
        min_train_cycles=args.min_train_cycles,
    )
    report = benchmark_summary_to_dict(summary)
    report["dataset"] = {
        "path": str(args.dataset),
        "max_subjects": args.max_subjects,
        "calibration_subjects": args.calibration_subjects,
        "validation_subjects": max(0, len(subjects) - args.calibration_subjects),
        "min_train_cycles": args.min_train_cycles,
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
