from pathlib import Path

from core.model import benchmark_train_validation_split, load_urteaga_cycle_lengths_npz, split_observation_sets

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATASET = PROJECT_ROOT / "tests" / "data" / "urteaga_cycle_lengths.npz"


def test_split_observation_sets_is_deterministic_and_disjoint():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    calibration, validation = split_observation_sets(subjects, calibration_subjects=400)
    assert len(calibration) == 400
    assert len(validation) == 800
    assert not (set(calibration) & set(validation))


def test_train_validation_benchmark_is_first_class_and_beats_baselines():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=1200)
    summary = benchmark_train_validation_split(subjects, calibration_subjects=400)
    period = summary.metric("period_v1")
    population = summary.metric("population_mean")
    recent3 = summary.metric("recent3_mean")

    assert period.fold_count > 6000
    assert period.mean_absolute_error_days < population.mean_absolute_error_days
    assert period.mean_absolute_error_days < recent3.mean_absolute_error_days
    assert 0.76 <= summary.p80_coverage <= 0.84
