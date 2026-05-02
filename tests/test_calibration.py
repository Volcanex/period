from pathlib import Path

from core.model import (
    benchmark_against_baselines,
    calibrate_interval_scale,
    calibrate_recent_blend_weight,
    calibrate_skip_prior_probability,
    estimate_population_prior,
    load_urteaga_cycle_lengths_npz,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATASET = PROJECT_ROOT / "tests" / "data" / "urteaga_cycle_lengths.npz"


def test_interval_scale_calibrates_on_held_out_subjects():
    all_subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    items = list(all_subjects.items())
    calibration = dict(items[:400])
    validation = dict(items[400:1200])

    uncalibrated_prior = estimate_population_prior(calibration)
    calibrated_prior = calibrate_interval_scale(calibration, prior=uncalibrated_prior)

    uncalibrated = benchmark_against_baselines(validation, prior=uncalibrated_prior)
    calibrated = benchmark_against_baselines(validation, prior=calibrated_prior)

    assert calibrated_prior.interval_scale <= uncalibrated_prior.interval_scale
    assert abs(calibrated.p80_coverage - 0.80) <= abs(uncalibrated.p80_coverage - 0.80)
    assert calibrated.metric("period_v1").mean_absolute_error_days == uncalibrated.metric("period_v1").mean_absolute_error_days


def test_recent_blend_is_only_kept_when_it_beats_hierarchical_posterior():
    all_subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    calibration = dict(list(all_subjects.items())[:400])

    base_prior = estimate_population_prior(calibration)
    blended_prior = calibrate_recent_blend_weight(calibration, prior=base_prior)

    assert blended_prior.recent_blend_weight == 0.0


def test_skip_prior_calibration_does_not_hurt_validation_mae():
    all_subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    items = list(all_subjects.items())
    calibration = dict(items[:400])
    validation = dict(items[400:1200])

    base_prior = estimate_population_prior(calibration)
    skip_prior = calibrate_skip_prior_probability(calibration, prior=base_prior)

    base = benchmark_against_baselines(validation, prior=base_prior)
    tuned = benchmark_against_baselines(validation, prior=skip_prior)

    assert tuned.metric("period_v1").mean_absolute_error_days <= base.metric("period_v1").mean_absolute_error_days + 0.05
