"""Bayesian-style cycle length reference model.

This dependency-free reference follows the literature shape without pretending
to reproduce a trained published model: population shrinkage for sparse users,
sequential state updates, and explicit self-tracking skip-artifact handling.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from math import exp, isfinite, pi, sqrt
from statistics import NormalDist
from pathlib import Path
from statistics import pstdev
from typing import Iterable, Sequence

import numpy as np

from core.contracts import Prediction


@dataclass(frozen=True)
class PopulationPrior:
    """Population-level prior used to shrink sparse individual histories."""

    mean_days: float = 29.0
    between_subject_sd: float = 4.0
    observation_sd: float = 3.5
    process_sd: float = 1.25
    interval_scale: float = 1.0
    recent_blend_weight: float = 0.0
    skip_prior_probability: float = 0.08
    min_cycle_days: int = 15
    max_cycle_days: int = 120

    @property
    def individual_variance(self) -> float:
        return self.between_subject_sd**2

    @property
    def observation_variance(self) -> float:
        return self.observation_sd**2

    @property
    def process_variance(self) -> float:
        return self.process_sd**2


@dataclass(frozen=True)
class CycleLengthObservation:
    subject_id: str
    cycle_index: int
    length_days: int
    skipped_tracking_suspected: bool = False


@dataclass(frozen=True)
class CycleModelState:
    subject_id: str
    cycle_count: int
    posterior_mean_days: float
    posterior_sd_days: float
    predictive_sd_days: float
    adjusted_lengths: tuple[float, ...]
    skip_probabilities: tuple[float, ...]
    algorithm_version: str = "period-hierarchical-skip-v1"
    recent_blend_weight: float = 0.0


@dataclass(frozen=True)
class CyclePrediction:
    subject_id: str
    expected_length_days: float
    p10_length_days: float
    p50_length_days: float
    p90_length_days: float
    skipped_tracking_probability: float
    elapsed_cycle_day: int | None
    algorithm_version: str

    def as_contract_payload(self) -> dict:
        return {
            "next_period": {
                "cycle_length_days": {
                    "p10": round(self.p10_length_days, 2),
                    "p50": round(self.p50_length_days, 2),
                    "p90": round(self.p90_length_days, 2),
                    "expected": round(self.expected_length_days, 2),
                }
            },
            "self_tracking": {
                "skipped_tracking_probability": round(self.skipped_tracking_probability, 4),
            },
            "elapsed_cycle_day": self.elapsed_cycle_day,
            "algorithm_version": self.algorithm_version,
        }

    def to_contract(
        self,
        prediction_id: str | None = None,
        generated_at: datetime | None = None,
    ) -> Prediction:
        """Convert this reference-model output into the public Prediction contract."""

        return Prediction(
            id=prediction_id or f"prediction-{self.subject_id}",
            subject_id=self.subject_id,
            generated_at=generated_at or datetime.now(UTC),
            algorithm_version=self.algorithm_version,
            next_period=self.as_contract_payload()["next_period"],
            ovulation=None,
            fertile_window=None,
            luteal_length=None,
            confidence=round(1.0 - self.skipped_tracking_probability, 4),
        )



@dataclass(frozen=True)
class ModelMetrics:
    name: str
    fold_count: int
    mean_absolute_error_days: float


@dataclass(frozen=True)
class ModelBenchmarkSummary:
    prior: PopulationPrior
    metrics: tuple[ModelMetrics, ...]
    p80_coverage: float
    folds: tuple[BacktestFold, ...]

    def metric(self, name: str) -> ModelMetrics:
        for metric in self.metrics:
            if metric.name == name:
                return metric
        raise KeyError(name)


@dataclass(frozen=True)
class BacktestFold:
    subject_id: str
    train_cycles: int
    actual_length_days: int
    predicted_p50_days: float
    absolute_error_days: float
    covered_by_80_interval: bool
    skipped_tracking_probability: float


@dataclass(frozen=True)
class BacktestSummary:
    fold_count: int
    mean_absolute_error_days: float
    p80_coverage: float
    folds: tuple[BacktestFold, ...]


def _normal_pdf(value: float, mean: float, sd: float) -> float:
    if sd <= 0:
        raise ValueError("sd must be positive")
    z = (value - mean) / sd
    return exp(-0.5 * z * z) / (sd * sqrt(2 * pi))


def _clip_probability(value: float) -> float:
    return max(0.0, min(1.0, value))


def _skip_probability(length_days: int, mean_days: float, prior: PopulationPrior, flagged: bool) -> float:
    if flagged:
        return 1.0
    if length_days < max(42, int(mean_days * 1.55)):
        return 0.0

    physiological = (1.0 - prior.skip_prior_probability) * _normal_pdf(
        length_days, mean_days, prior.observation_sd * 1.8
    )
    skipped = prior.skip_prior_probability * _normal_pdf(
        length_days / 2.0, mean_days, prior.observation_sd
    )
    denom = physiological + skipped
    if denom <= 0 or not isfinite(denom):
        return 0.0
    return _clip_probability(skipped / denom)


def _adjust_length(length_days: int, skip_probability: float) -> float:
    return (1.0 - skip_probability) * length_days + skip_probability * (length_days / 2.0)


def fit_cycle_model(
    observations: Sequence[CycleLengthObservation],
    prior: PopulationPrior | None = None,
) -> CycleModelState:
    """Fit an individual cycle-length state with population shrinkage."""

    prior = prior or PopulationPrior()
    if not observations:
        return CycleModelState(
            subject_id="unknown",
            cycle_count=0,
            posterior_mean_days=prior.mean_days,
            posterior_sd_days=prior.between_subject_sd,
            predictive_sd_days=prior.interval_scale * sqrt(prior.individual_variance + prior.observation_variance + prior.process_variance),
            adjusted_lengths=(),
            skip_probabilities=(),
            recent_blend_weight=prior.recent_blend_weight,
        )

    ordered = sorted(observations, key=lambda obs: obs.cycle_index)
    subject_ids = {obs.subject_id for obs in ordered}
    if len(subject_ids) != 1:
        raise ValueError("fit_cycle_model expects observations for exactly one subject")

    adjusted: list[float] = []
    skips: list[float] = []
    running_mean = prior.mean_days
    for obs in ordered:
        if obs.length_days < prior.min_cycle_days or obs.length_days > prior.max_cycle_days:
            raise ValueError(f"cycle length out of supported range: {obs.length_days}")
        skip_p = _skip_probability(obs.length_days, running_mean, prior, obs.skipped_tracking_suspected)
        adjusted_length = _adjust_length(obs.length_days, skip_p)
        skips.append(skip_p)
        adjusted.append(adjusted_length)
        running_mean = sum(adjusted) / len(adjusted)

    n = len(adjusted)
    prior_precision = 1.0 / prior.individual_variance
    data_precision = n / prior.observation_variance
    posterior_variance = 1.0 / (prior_precision + data_precision)
    posterior_mean = posterior_variance * (
        prior.mean_days * prior_precision + sum(adjusted) / prior.observation_variance
    )
    predictive_variance = posterior_variance + prior.observation_variance + prior.process_variance
    predictive_sd = prior.interval_scale * sqrt(predictive_variance)

    return CycleModelState(
        subject_id=ordered[0].subject_id,
        cycle_count=n,
        posterior_mean_days=posterior_mean,
        posterior_sd_days=sqrt(posterior_variance),
        predictive_sd_days=predictive_sd,
        adjusted_lengths=tuple(adjusted),
        skip_probabilities=tuple(skips),
        recent_blend_weight=prior.recent_blend_weight,
    )


def _blend_recent_mean(state: CycleModelState) -> float:
    # The blend weight is encoded by scaling predictive_sd_days? No: this stays
    # source-compatible by reading a private attribute only when present.
    weight = getattr(state, "recent_blend_weight", 0.0)
    if weight <= 0 or not state.adjusted_lengths:
        return state.posterior_mean_days
    recent = state.adjusted_lengths[-3:]
    recent_mean = sum(recent) / len(recent)
    return (1.0 - weight) * state.posterior_mean_days + weight * recent_mean


def _condition_on_elapsed(mean: float, sd: float, elapsed_cycle_day: int | None) -> tuple[float, float]:
    if elapsed_cycle_day is None or elapsed_cycle_day <= 0:
        return mean, sd
    lower = float(elapsed_cycle_day + 1)
    if lower <= mean - 4 * sd:
        return mean, sd

    dist = NormalDist(mean, sd)
    alpha = (lower - mean) / sd
    tail = 1.0 - dist.cdf(lower)
    if tail < 1e-6:
        return lower, max(1.0, sd * 0.35)
    phi = _normal_pdf(alpha, 0.0, 1.0)
    lambda_ = phi / tail
    conditioned_mean = mean + sd * lambda_
    conditioned_variance = sd * sd * (1.0 + alpha * lambda_ - lambda_ * lambda_)
    return conditioned_mean, sqrt(max(conditioned_variance, 1.0))


def predict_next_cycle(state: CycleModelState, elapsed_cycle_day: int | None = None) -> CyclePrediction:
    """Predict next cycle length, optionally updated for an ongoing cycle day."""

    base_mean = _blend_recent_mean(state)
    mean, sd = _condition_on_elapsed(base_mean, state.predictive_sd_days, elapsed_cycle_day)
    dist = NormalDist(mean, sd)
    recent_skips = state.skip_probabilities[-3:]
    skip_probability = _clip_probability(sum(recent_skips) / len(recent_skips) if recent_skips else 0.0)
    return CyclePrediction(
        subject_id=state.subject_id,
        expected_length_days=mean,
        p10_length_days=max(1.0, dist.inv_cdf(0.10)),
        p50_length_days=max(1.0, dist.inv_cdf(0.50)),
        p90_length_days=max(1.0, dist.inv_cdf(0.90)),
        skipped_tracking_probability=skip_probability,
        elapsed_cycle_day=elapsed_cycle_day,
        algorithm_version=state.algorithm_version,
    )


def backtest_subjects(
    subjects: dict[str, Sequence[int]],
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> BacktestSummary:
    """Rolling-origin backtest over a small cycle-length fixture."""

    prior = prior or PopulationPrior()
    folds: list[BacktestFold] = []
    for subject_id, lengths in subjects.items():
        observations = [
            CycleLengthObservation(subject_id=subject_id, cycle_index=i, length_days=length)
            for i, length in enumerate(lengths)
        ]
        for target_index in range(min_train_cycles, len(observations)):
            train = observations[:target_index]
            actual = observations[target_index]
            state = fit_cycle_model(train, prior)
            prediction = predict_next_cycle(state)
            folds.append(
                BacktestFold(
                    subject_id=subject_id,
                    train_cycles=len(train),
                    actual_length_days=actual.length_days,
                    predicted_p50_days=prediction.p50_length_days,
                    absolute_error_days=abs(actual.length_days - prediction.p50_length_days),
                    covered_by_80_interval=prediction.p10_length_days <= actual.length_days <= prediction.p90_length_days,
                    skipped_tracking_probability=prediction.skipped_tracking_probability,
                )
            )

    if not folds:
        return BacktestSummary(fold_count=0, mean_absolute_error_days=0.0, p80_coverage=0.0, folds=())
    return BacktestSummary(
        fold_count=len(folds),
        mean_absolute_error_days=sum(f.absolute_error_days for f in folds) / len(folds),
        p80_coverage=sum(1 for f in folds if f.covered_by_80_interval) / len(folds),
        folds=tuple(folds),
    )


def load_cycle_length_fixture(rows: Iterable[dict]) -> dict[str, list[int]]:
    subjects: dict[str, list[int]] = {}
    for row in sorted(rows, key=lambda item: (str(item["subject_id"]), int(item["cycle_index"]))):
        subjects.setdefault(str(row["subject_id"]), []).append(int(row["length_days"]))
    return subjects


def load_urteaga_cycle_lengths_npz(
    path: str | Path,
    max_subjects: int | None = None,
) -> dict[str, list[CycleLengthObservation]]:
    """Load the public Urteaga/Li cycle-length NPZ benchmark fixture."""

    data = np.load(Path(path), allow_pickle=True)
    lengths = data["cycle_lengths"]
    skipped = data["cycle_skipped"] if "cycle_skipped" in data.files else np.zeros_like(lengths)
    limit = lengths.shape[0] if max_subjects is None else min(max_subjects, lengths.shape[0])
    subjects: dict[str, list[CycleLengthObservation]] = {}
    for subject_index in range(limit):
        observations: list[CycleLengthObservation] = []
        for cycle_index, raw_length in enumerate(lengths[subject_index]):
            length = int(raw_length)
            if 15 <= length <= 120:
                observations.append(
                    CycleLengthObservation(
                        subject_id=f"urteaga-{subject_index}",
                        cycle_index=cycle_index,
                        length_days=length,
                        skipped_tracking_suspected=bool(int(skipped[subject_index][cycle_index])),
                    )
                )
        if observations:
            subjects[f"urteaga-{subject_index}"] = observations
    return subjects


def estimate_population_prior(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    fallback: PopulationPrior | None = None,
) -> PopulationPrior:
    """Estimate population hyperpriors from benchmark cycle histories."""

    fallback = fallback or PopulationPrior()
    subject_means: list[float] = []
    residuals: list[float] = []
    skip_count = 0
    total_count = 0
    for observations in observation_sets.values():
        adjusted = [obs.length_days / 2.0 if obs.skipped_tracking_suspected else float(obs.length_days) for obs in observations]
        if not adjusted:
            continue
        mean = sum(adjusted) / len(adjusted)
        subject_means.append(mean)
        residuals.extend(value - mean for value in adjusted)
        skip_count += sum(1 for obs in observations if obs.skipped_tracking_suspected)
        total_count += len(observations)

    if not subject_means:
        return fallback

    mean_days = sum(subject_means) / len(subject_means)
    between_sd = max(1.0, pstdev(subject_means) if len(subject_means) > 1 else fallback.between_subject_sd)
    observation_sd = max(1.0, pstdev(residuals) if len(residuals) > 1 else fallback.observation_sd)
    skip_prior = max(0.01, min(0.35, skip_count / total_count if total_count else fallback.skip_prior_probability))
    return PopulationPrior(
        mean_days=mean_days,
        between_subject_sd=between_sd,
        observation_sd=observation_sd,
        process_sd=max(0.75, min(2.5, observation_sd / 3.0)),
        interval_scale=fallback.interval_scale,
        recent_blend_weight=fallback.recent_blend_weight,
        skip_prior_probability=skip_prior,
        min_cycle_days=fallback.min_cycle_days,
        max_cycle_days=fallback.max_cycle_days,
    )


def backtest_observation_sets(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> BacktestSummary:
    prior = prior or estimate_population_prior(observation_sets)
    folds: list[BacktestFold] = []
    for subject_id, observations in observation_sets.items():
        ordered = sorted(observations, key=lambda obs: obs.cycle_index)
        for target_index in range(min_train_cycles, len(ordered)):
            train = ordered[:target_index]
            actual = ordered[target_index]
            state = fit_cycle_model(train, prior)
            prediction = predict_next_cycle(state)
            actual_length = actual.length_days / 2.0 if actual.skipped_tracking_suspected else float(actual.length_days)
            folds.append(
                BacktestFold(
                    subject_id=subject_id,
                    train_cycles=len(train),
                    actual_length_days=int(round(actual_length)),
                    predicted_p50_days=prediction.p50_length_days,
                    absolute_error_days=abs(actual_length - prediction.p50_length_days),
                    covered_by_80_interval=prediction.p10_length_days <= actual_length <= prediction.p90_length_days,
                    skipped_tracking_probability=prediction.skipped_tracking_probability,
                )
            )
    if not folds:
        return BacktestSummary(fold_count=0, mean_absolute_error_days=0.0, p80_coverage=0.0, folds=())
    return BacktestSummary(
        fold_count=len(folds),
        mean_absolute_error_days=sum(f.absolute_error_days for f in folds) / len(folds),
        p80_coverage=sum(1 for f in folds if f.covered_by_80_interval) / len(folds),
        folds=tuple(folds),
    )


def calibrate_skip_prior_probability(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    candidate_probabilities: Sequence[float] | None = None,
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> PopulationPrior:
    """Choose the skip-mixture prior by validation MAE."""

    base_prior = prior or estimate_population_prior(observation_sets)
    candidate_probabilities = candidate_probabilities or (0.02, 0.05, 0.08, 0.10, 0.12, 0.16, 0.20, 0.25)
    best_prior = base_prior
    best_mae = float("inf")
    for probability in candidate_probabilities:
        candidate = PopulationPrior(
            mean_days=base_prior.mean_days,
            between_subject_sd=base_prior.between_subject_sd,
            observation_sd=base_prior.observation_sd,
            process_sd=base_prior.process_sd,
            interval_scale=base_prior.interval_scale,
            recent_blend_weight=base_prior.recent_blend_weight,
            skip_prior_probability=probability,
            min_cycle_days=base_prior.min_cycle_days,
            max_cycle_days=base_prior.max_cycle_days,
        )
        summary = backtest_observation_sets(
            observation_sets, min_train_cycles=min_train_cycles, prior=candidate
        )
        mae = summary.mean_absolute_error_days
        if mae < best_mae:
            best_prior = candidate
            best_mae = mae
    return best_prior


def calibrate_recent_blend_weight(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    candidate_weights: Sequence[float] | None = None,
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> PopulationPrior:
    """Choose a simple posterior/recent-history blend by validation MAE."""

    base_prior = prior or estimate_population_prior(observation_sets)
    candidate_weights = candidate_weights or (0.0, 0.10, 0.20, 0.30, 0.40, 0.50)
    best_prior = base_prior
    best_mae = float("inf")
    for weight in candidate_weights:
        candidate = PopulationPrior(
            mean_days=base_prior.mean_days,
            between_subject_sd=base_prior.between_subject_sd,
            observation_sd=base_prior.observation_sd,
            process_sd=base_prior.process_sd,
            interval_scale=base_prior.interval_scale,
            recent_blend_weight=weight,
            skip_prior_probability=base_prior.skip_prior_probability,
            min_cycle_days=base_prior.min_cycle_days,
            max_cycle_days=base_prior.max_cycle_days,
        )
        summary = backtest_observation_sets(
            observation_sets, min_train_cycles=min_train_cycles, prior=candidate
        )
        mae = summary.mean_absolute_error_days
        if mae < best_mae:
            best_prior = candidate
            best_mae = mae
    return best_prior


def calibrate_interval_scale(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    target_coverage: float = 0.80,
    candidate_scales: Sequence[float] | None = None,
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> PopulationPrior:
    """Choose interval width on calibration subjects without changing point predictions."""

    base_prior = prior or estimate_population_prior(observation_sets)
    candidate_scales = candidate_scales or (0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.35, 1.50)
    best_prior = base_prior
    best_error = float("inf")
    best_width = float("inf")
    for scale in candidate_scales:
        candidate = PopulationPrior(
            mean_days=base_prior.mean_days,
            between_subject_sd=base_prior.between_subject_sd,
            observation_sd=base_prior.observation_sd,
            process_sd=base_prior.process_sd,
            interval_scale=scale,
            recent_blend_weight=base_prior.recent_blend_weight,
            skip_prior_probability=base_prior.skip_prior_probability,
            min_cycle_days=base_prior.min_cycle_days,
            max_cycle_days=base_prior.max_cycle_days,
        )
        summary = backtest_observation_sets(
            observation_sets, min_train_cycles=min_train_cycles, prior=candidate
        )
        coverage_error = abs(summary.p80_coverage - target_coverage)
        if coverage_error < best_error or (coverage_error == best_error and scale < best_width):
            best_prior = candidate
            best_error = coverage_error
            best_width = scale
    return best_prior


def benchmark_against_baselines(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    min_train_cycles: int = 3,
    prior: PopulationPrior | None = None,
) -> ModelBenchmarkSummary:
    prior = prior or estimate_population_prior(observation_sets)
    model_summary = backtest_observation_sets(observation_sets, min_train_cycles=min_train_cycles, prior=prior)
    baseline_errors: dict[str, list[float]] = {"population_mean": [], "personal_mean": [], "recent3_mean": []}

    for observations in observation_sets.values():
        ordered = sorted(observations, key=lambda obs: obs.cycle_index)
        adjusted = [obs.length_days / 2.0 if obs.skipped_tracking_suspected else float(obs.length_days) for obs in ordered]
        for target_index in range(min_train_cycles, len(adjusted)):
            train = adjusted[:target_index]
            actual = adjusted[target_index]
            baseline_errors["population_mean"].append(abs(actual - prior.mean_days))
            baseline_errors["personal_mean"].append(abs(actual - (sum(train) / len(train))))
            recent = train[-3:]
            baseline_errors["recent3_mean"].append(abs(actual - (sum(recent) / len(recent))))

    metrics = [
        ModelMetrics("period_v1", model_summary.fold_count, model_summary.mean_absolute_error_days),
    ]
    for name, errors in baseline_errors.items():
        metrics.append(ModelMetrics(name, len(errors), sum(errors) / len(errors) if errors else 0.0))
    return ModelBenchmarkSummary(
        prior=prior,
        metrics=tuple(metrics),
        p80_coverage=model_summary.p80_coverage,
        folds=model_summary.folds,
    )


def summarize_folds_by_train_cycle(folds: Sequence[BacktestFold]) -> dict[int, ModelMetrics]:
    """Summarize MAE by number of observed training cycles."""

    buckets: dict[int, list[float]] = {}
    for fold in folds:
        buckets.setdefault(fold.train_cycles, []).append(fold.absolute_error_days)
    return {
        train_cycles: ModelMetrics(
            name=f"train_cycles_{train_cycles}",
            fold_count=len(errors),
            mean_absolute_error_days=sum(errors) / len(errors),
        )
        for train_cycles, errors in sorted(buckets.items())
    }


def summarize_folds_by_skip_probability(
    folds: Sequence[BacktestFold],
    threshold: float = 0.20,
) -> dict[str, ModelMetrics]:
    """Summarize MAE for low/high predicted skipped-tracking risk."""

    buckets = {"low_skip_risk": [], "high_skip_risk": []}
    for fold in folds:
        key = "high_skip_risk" if fold.skipped_tracking_probability >= threshold else "low_skip_risk"
        buckets[key].append(fold.absolute_error_days)
    return {
        name: ModelMetrics(
            name=name,
            fold_count=len(errors),
            mean_absolute_error_days=sum(errors) / len(errors) if errors else 0.0,
        )
        for name, errors in buckets.items()
    }


def split_observation_sets(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    calibration_subjects: int,
) -> tuple[dict[str, Sequence[CycleLengthObservation]], dict[str, Sequence[CycleLengthObservation]]]:
    """Deterministically split subjects into calibration and validation sets."""

    items = list(sorted(observation_sets.items()))
    calibration = dict(items[:calibration_subjects])
    validation = dict(items[calibration_subjects:])
    return calibration, validation


def benchmark_train_validation_split(
    observation_sets: dict[str, Sequence[CycleLengthObservation]],
    calibration_subjects: int,
    min_train_cycles: int = 3,
    calibrate_intervals: bool = True,
) -> ModelBenchmarkSummary:
    """Learn priors on calibration users and evaluate on held-out users."""

    calibration, validation = split_observation_sets(observation_sets, calibration_subjects)
    prior = estimate_population_prior(calibration)
    if calibrate_intervals:
        prior = calibrate_interval_scale(calibration, min_train_cycles=min_train_cycles, prior=prior)
    return benchmark_against_baselines(validation, min_train_cycles=min_train_cycles, prior=prior)


def benchmark_summary_to_dict(summary: ModelBenchmarkSummary) -> dict:
    """Return a stable JSON-serializable benchmark summary."""

    return {
        "prior": asdict(summary.prior),
        "metrics": [asdict(metric) for metric in summary.metrics],
        "p80_coverage": summary.p80_coverage,
        "fold_count": len(summary.folds),
    }
