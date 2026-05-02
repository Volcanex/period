from pathlib import Path

from core.model import (
    benchmark_against_baselines,
    calibrate_interval_scale,
    estimate_population_prior,
    load_urteaga_cycle_lengths_npz,
    summarize_folds_by_skip_probability,
    summarize_folds_by_train_cycle,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATASET = PROJECT_ROOT / "tests" / "data" / "urteaga_cycle_lengths.npz"


def _validation_summary():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    items = list(subjects.items())
    calibration = dict(items[:400])
    validation = dict(items[400:1200])
    prior = calibrate_interval_scale(calibration, prior=estimate_population_prior(calibration))
    return benchmark_against_baselines(validation, prior=prior)


def test_cycle_count_segments_are_reportable():
    summary = _validation_summary()
    by_cycle = summarize_folds_by_train_cycle(summary.folds)
    assert set(by_cycle) >= {3, 4, 5, 6, 7, 8, 9}
    assert all(metric.fold_count > 0 for metric in by_cycle.values())
    assert by_cycle[9].mean_absolute_error_days <= by_cycle[3].mean_absolute_error_days + 0.75


def test_skip_probability_segments_are_reportable():
    summary = _validation_summary()
    by_skip = summarize_folds_by_skip_probability(summary.folds, threshold=0.20)
    assert by_skip["low_skip_risk"].fold_count > 0
    assert by_skip["high_skip_risk"].fold_count > 0
