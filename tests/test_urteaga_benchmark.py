from pathlib import Path

from core.model import benchmark_against_baselines, estimate_population_prior, load_urteaga_cycle_lengths_npz

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATASET = PROJECT_ROOT / "tests" / "data" / "urteaga_cycle_lengths.npz"


def test_public_urteaga_npz_fixture_loads_cycle_histories():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=25)
    assert len(subjects) == 25
    assert all(len(observations) >= 8 for observations in subjects.values())


def test_population_prior_is_learned_from_urteaga_fixture():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=500)
    prior = estimate_population_prior(subjects)
    assert 18 <= prior.mean_days <= 35
    assert 1 <= prior.between_subject_sd <= 12
    assert 1 <= prior.observation_sd <= 12
    assert 0.01 <= prior.skip_prior_probability <= 0.35


def test_period_v1_beats_population_baseline_on_urteaga_fixture():
    subjects = load_urteaga_cycle_lengths_npz(DATASET, max_subjects=800)
    summary = benchmark_against_baselines(subjects, min_train_cycles=3)
    period_v1 = summary.metric("period_v1")
    population = summary.metric("population_mean")
    recent3 = summary.metric("recent3_mean")
    assert period_v1.fold_count > 5000
    assert period_v1.mean_absolute_error_days < population.mean_absolute_error_days
    assert period_v1.mean_absolute_error_days <= recent3.mean_absolute_error_days + 0.25
    assert summary.p80_coverage >= 0.70
