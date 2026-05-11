"""Backend PMDD pattern evaluation and synthetic backtesting.

Scoring is aligned to DRSP/C-PASS-style prospective logic:
- daily 1-6 symptom ratings
- premenstrual week days -7 to -1
- postmenstrual week days 4 to 10
- 30% relative elevation using the woman's range-of-scale-used denominator
- postmenstrual clearance max <= 3
- premenstrual severity max >= 4
- premenstrual duration >= 2 days at 4+
- >= 1 core symptom, >= 5 total symptoms, and >= 1 impairment symptom
- >= 2 positive cycles for a repeated PMDD-style pattern
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

from core.contracts import (
    EvidenceReference,
    ObservationEvent,
    PmddCycleEvaluation,
    PmddEvaluationResult,
    PmddSymptomCycleScore,
)

PMDD_ANALYZER_CODE = "pmdd_pattern_v1"
PMDD_ANALYZER_VERSION = "2026.05.08"

_BASE_EVIDENCE = EvidenceReference(
    source="DRSP/C-PASS-style PMDD backend scoring",
    assumption="Uses prospective daily DRSP-style ratings and conservative cycle criteria to identify repeated PMDD-style patterns without collapsing uncertainty.",
    confidence=0.62,
    version=PMDD_ANALYZER_VERSION,
    review_status="draft",
)

_CORE_GROUPS: dict[str, tuple[str, ...]] = {
    "affective_lability": ("drsp_mood_swings", "drsp_rejection_sensitivity"),
    "irritability_anger": ("drsp_anger_irritability", "drsp_interpersonal_conflict"),
    "depressed_mood": ("drsp_depressed_mood", "drsp_hopelessness", "drsp_worthlessness_guilt"),
    "anxiety_tension": ("drsp_anxiety_tension",),
}

_SECONDARY_GROUPS: dict[str, tuple[str, ...]] = {
    "less_interest": ("drsp_less_interest",),
    "difficulty_concentrating": ("drsp_difficulty_concentrating",),
    "lethargy": ("drsp_lethargy",),
    "appetite_change": ("drsp_appetite_overeating", "drsp_food_cravings"),
    "sleep_change": ("drsp_hypersomnia", "drsp_insomnia"),
    "overwhelmed": ("drsp_overwhelmed", "drsp_out_of_control"),
    "physical_symptoms": (
        "drsp_breast_tenderness",
        "drsp_bloating_weight_gain",
        "drsp_headache",
        "drsp_joint_muscle_pain",
    ),
}

_IMPAIRMENT_GROUPS: dict[str, tuple[str, ...]] = {
    "productivity_impairment": ("drsp_productivity_impairment",),
    "social_impairment": ("drsp_social_impairment",),
    "relationship_impairment": ("drsp_relationship_impairment",),
}

_ALL_GROUPS = {**_CORE_GROUPS, **_SECONDARY_GROUPS, **_IMPAIRMENT_GROUPS}
_DRSP_CODES = {code for codes in _ALL_GROUPS.values() for code in codes}

_BLEED_STARTS = {"light", "medium", "heavy"}


@dataclass(frozen=True)
class _CycleSignal:
    onset: date
    pre_coverage: float
    post_coverage: float
    positive: bool
    subthreshold: bool
    core_symptom_count: int
    total_symptom_count: int
    impairment_count: int
    symptom_scores: tuple[PmddSymptomCycleScore, ...]
    qualifying_core_symptoms: tuple[str, ...]
    qualifying_secondary_symptoms: tuple[str, ...]
    qualifying_impairment_symptoms: tuple[str, ...]
    suppressors: tuple[str, ...]


@dataclass(frozen=True)
class PmddBacktestCase:
    case_id: str
    subject_id: str
    expected_status: str
    observations: tuple[ObservationEvent, ...]


@dataclass(frozen=True)
class PmddBacktestFold:
    case_id: str
    expected_status: str
    predicted_status: str
    status_match: bool
    confidence: str
    coverage: float
    supporting_cycle_count: int


@dataclass(frozen=True)
class PmddBacktestSummary:
    fold_count: int
    exact_match_rate: float
    folds: tuple[PmddBacktestFold, ...]


def load_pmdd_backtest_cases(rows: list[dict]) -> list[PmddBacktestCase]:
    cases: list[PmddBacktestCase] = []
    for row in rows:
        observations = tuple(
            ObservationEvent(
                id=event["id"],
                subject_id=event["subject_id"],
                tracker_code=event["tracker_code"],
                observed_at=datetime.fromisoformat(event["observed_at"].replace("Z", "+00:00")),
                observed_on=date.fromisoformat(event["observed_on"]) if event.get("observed_on") else None,
                source=event["source"],
                value=event["value"],
                unit=event.get("unit"),
                raw_payload=event.get("raw_payload"),
                note=event.get("note"),
            )
            for event in row["observations"]
        )
        cases.append(
            PmddBacktestCase(
                case_id=row["case_id"],
                subject_id=row["subject_id"],
                expected_status=row["expected_status"],
                observations=observations,
            )
        )
    return cases


def load_pmdd_backtest_fixture(path: Path | None = None) -> list[PmddBacktestCase]:
    fixture_path = path or Path(__file__).resolve().parents[2] / "tests" / "data" / "pmdd_backtest_cases.json"
    return load_pmdd_backtest_cases(json.loads(fixture_path.read_text(encoding="utf-8")))


def backtest_pmdd_cases(cases: list[PmddBacktestCase]) -> PmddBacktestSummary:
    folds: list[PmddBacktestFold] = []
    for case in cases:
        result = evaluate_pmdd(case.subject_id, list(case.observations))
        folds.append(
            PmddBacktestFold(
                case_id=case.case_id,
                expected_status=case.expected_status,
                predicted_status=result.status,
                status_match=result.status == case.expected_status,
                confidence=result.confidence,
                coverage=round(result.coverage, 4),
                supporting_cycle_count=result.supporting_cycle_count,
            )
        )
    exact_match_rate = sum(1 for fold in folds if fold.status_match) / len(folds) if folds else 0.0
    return PmddBacktestSummary(
        fold_count=len(folds),
        exact_match_rate=exact_match_rate,
        folds=tuple(folds),
    )


def pmdd_backtest_summary_to_dict(summary: PmddBacktestSummary) -> dict:
    by_expected: dict[str, int] = {}
    by_predicted: dict[str, int] = {}
    for fold in summary.folds:
        by_expected[fold.expected_status] = by_expected.get(fold.expected_status, 0) + 1
        by_predicted[fold.predicted_status] = by_predicted.get(fold.predicted_status, 0) + 1
    return {
        "analyzer_code": PMDD_ANALYZER_CODE,
        "analyzer_version": PMDD_ANALYZER_VERSION,
        "fold_count": summary.fold_count,
        "exact_match_rate": round(summary.exact_match_rate, 4),
        "expected_status_counts": by_expected,
        "predicted_status_counts": by_predicted,
        "folds": [asdict(fold) for fold in summary.folds],
    }


def evaluate_pmdd(subject_id: str, observations: list[ObservationEvent]) -> PmddEvaluationResult:
    ordered = sorted(observations, key=lambda event: (_observed_day(event), event.observed_at))
    cycles = _cycle_signals(ordered)
    suppressors = sorted({flag for cycle in cycles for flag in cycle.suppressors})
    positive_cycles = [cycle for cycle in cycles if cycle.positive]
    subthreshold_cycles = [cycle for cycle in cycles if cycle.subthreshold]
    rich_logged = any(event.tracker_code in _DRSP_CODES for event in ordered)
    coverage = (
        sum((cycle.pre_coverage + cycle.post_coverage) / 2 for cycle in cycles) / len(cycles)
        if cycles
        else 0.0
    )
    activation_score = float(max((cycle.total_symptom_count for cycle in cycles), default=0))
    confidence = _confidence_label(
        suppressed=bool(suppressors),
        supporting_cycle_count=len(positive_cycles),
        coverage=coverage,
    )
    evidence_summary = f"{len(cycles)} recent windows · {' · '.join(suppressors) if suppressors else 'no major suppressors'}"
    generated_at = datetime.now(UTC)
    cycle_evaluations = [
        PmddCycleEvaluation(
            onset_date=cycle.onset,
            premenstrual_coverage=cycle.pre_coverage,
            postmenstrual_coverage=cycle.post_coverage,
            evaluable=(cycle.pre_coverage >= 0.57 and cycle.post_coverage >= 0.57),
            core_symptom_count=cycle.core_symptom_count,
            total_symptom_count=cycle.total_symptom_count,
            impairment_count=cycle.impairment_count,
            core_symptom_rule_met=cycle.core_symptom_count >= 1,
            total_symptom_rule_met=cycle.total_symptom_count >= 5,
            impairment_rule_met=cycle.impairment_count >= 1,
            cycle_positive=cycle.positive,
            qualifying_core_symptoms=list(cycle.qualifying_core_symptoms),
            qualifying_secondary_symptoms=list(cycle.qualifying_secondary_symptoms),
            qualifying_impairment_symptoms=list(cycle.qualifying_impairment_symptoms),
            symptom_scores=list(cycle.symptom_scores),
        )
        for cycle in cycles
    ]
    meets_content_rule = any(cycle.core_symptom_count >= 1 and cycle.total_symptom_count >= 5 for cycle in cycles)
    meets_impairment_rule = any(cycle.impairment_count >= 1 for cycle in cycles)
    meets_chronicity_rule = len(positive_cycles) >= 2

    if suppressors:
        return PmddEvaluationResult(
            analyzer_code=PMDD_ANALYZER_CODE,
            analyzer_version=PMDD_ANALYZER_VERSION,
            subject_id=subject_id,
            generated_at=generated_at,
            status="suppressed",
            confidence=confidence,
            supporting_cycle_count=0,
            evaluable_cycle_count=len(cycles),
            rich_pattern_logged=rich_logged,
            pack_recommended=False,
            coverage=coverage,
            activation_score=activation_score,
            positive_cycle_count=len(positive_cycles),
            meets_chronicity_rule=meets_chronicity_rule,
            meets_drsp_content_rule=meets_content_rule,
            meets_drsp_impairment_rule=meets_impairment_rule,
            suppressors=suppressors,
            summary="PMDD evaluation is suppressed because postpartum, pregnancy, lactation, or medication-change context makes a DRSP-style cyclic reading less reliable.",
            evidence_summary=evidence_summary,
            cycle_evaluations=cycle_evaluations,
            recommended_actions=[
                "Continue daily DRSP-style symptom logging and reproductive-context logging.",
                "Differentiate possible PMDD from premenstrual exacerbation or other overlapping disorders with clinician review.",
            ],
            evidence=[_BASE_EVIDENCE],
        )

    if len(positive_cycles) >= 2:
        return PmddEvaluationResult(
            analyzer_code=PMDD_ANALYZER_CODE,
            analyzer_version=PMDD_ANALYZER_VERSION,
            subject_id=subject_id,
            generated_at=generated_at,
            status="pattern",
            confidence=confidence,
            supporting_cycle_count=len(positive_cycles),
            evaluable_cycle_count=len(cycles),
            rich_pattern_logged=True,
            pack_recommended=False,
            coverage=coverage,
            activation_score=activation_score,
            positive_cycle_count=len(positive_cycles),
            meets_chronicity_rule=meets_chronicity_rule,
            meets_drsp_content_rule=meets_content_rule,
            meets_drsp_impairment_rule=meets_impairment_rule,
            suppressors=[],
            summary="At least two recent cycles meet DRSP/C-PASS-like PMDD pattern criteria: one or more core symptoms, five or more total symptoms, postmenstrual clearance, and impairment.",
            evidence_summary=evidence_summary,
            cycle_evaluations=cycle_evaluations,
            recommended_actions=[
                "Continue prospective daily ratings for ongoing confirmation and trend stability.",
                "Review the cycle-level symptom and impairment pattern with a clinician if diagnosis or treatment decisions are needed.",
            ],
            evidence=[_BASE_EVIDENCE],
        )

    if subthreshold_cycles:
        return PmddEvaluationResult(
            analyzer_code=PMDD_ANALYZER_CODE,
            analyzer_version=PMDD_ANALYZER_VERSION,
            subject_id=subject_id,
            generated_at=generated_at,
            status="activation",
            confidence=confidence,
            supporting_cycle_count=len(subthreshold_cycles),
            evaluable_cycle_count=len(cycles),
            rich_pattern_logged=rich_logged,
            pack_recommended=not rich_logged,
            coverage=coverage,
            activation_score=activation_score,
            positive_cycle_count=len(positive_cycles),
            meets_chronicity_rule=meets_chronicity_rule,
            meets_drsp_content_rule=meets_content_rule,
            meets_drsp_impairment_rule=meets_impairment_rule,
            suppressors=[],
            summary="At least one cycle shows clinically meaningful premenstrual activation, but the repeated two-cycle PMDD threshold or full DRSP content/impairment threshold is not yet met.",
            evidence_summary=evidence_summary,
            cycle_evaluations=cycle_evaluations,
            recommended_actions=[
                "Continue daily DRSP-style logging through at least one additional complete cycle.",
            ],
            evidence=[_BASE_EVIDENCE],
        )

    if not cycles or coverage < 0.4:
        return PmddEvaluationResult(
            analyzer_code=PMDD_ANALYZER_CODE,
            analyzer_version=PMDD_ANALYZER_VERSION,
            subject_id=subject_id,
            generated_at=generated_at,
            status="insufficient_data",
            confidence=confidence,
            supporting_cycle_count=0,
            evaluable_cycle_count=len(cycles),
            rich_pattern_logged=rich_logged,
            pack_recommended=True,
            coverage=coverage,
            activation_score=activation_score,
            positive_cycle_count=len(positive_cycles),
            meets_chronicity_rule=meets_chronicity_rule,
            meets_drsp_content_rule=meets_content_rule,
            meets_drsp_impairment_rule=meets_impairment_rule,
            suppressors=[],
            summary="More prospective daily DRSP-style coverage is needed before PMDD evaluation can apply symptom, cyclicity, and impairment thresholds reliably.",
            evidence_summary=evidence_summary,
            cycle_evaluations=cycle_evaluations,
            recommended_actions=[
                "Log daily symptoms on the 1-6 DRSP-style scale for at least two consecutive cycles.",
            ],
            evidence=[_BASE_EVIDENCE],
        )

    return PmddEvaluationResult(
        analyzer_code=PMDD_ANALYZER_CODE,
        analyzer_version=PMDD_ANALYZER_VERSION,
        subject_id=subject_id,
        generated_at=generated_at,
        status="quiet",
        confidence=confidence,
        supporting_cycle_count=0,
        evaluable_cycle_count=len(cycles),
        rich_pattern_logged=rich_logged,
        pack_recommended=not rich_logged,
        coverage=coverage,
        activation_score=activation_score,
        positive_cycle_count=len(positive_cycles),
        meets_chronicity_rule=meets_chronicity_rule,
        meets_drsp_content_rule=meets_content_rule,
        meets_drsp_impairment_rule=meets_impairment_rule,
        suppressors=[],
        summary="Recent evaluable cycles did not meet the DRSP/C-PASS-like threshold for repeated PMDD-style patterning.",
        evidence_summary=evidence_summary,
        cycle_evaluations=cycle_evaluations,
        recommended_actions=[],
        evidence=[_BASE_EVIDENCE],
    )


def _cycle_signals(observations: list[ObservationEvent]) -> list[_CycleSignal]:
    starts = _bleeding_start_dates(observations)
    if not starts:
        return []
    latest_day = _observed_day(observations[-1]) if observations else None
    cycles: list[_CycleSignal] = []
    for onset in starts:
        if latest_day is None or latest_day < onset + timedelta(days=10):
            continue
        pre_days = [onset - timedelta(days=i) for i in range(7, 0, -1)]
        post_days = [onset + timedelta(days=i) for i in range(4, 11)]
        pre_coverage = _coverage(pre_days, observations)
        post_coverage = _coverage(post_days, observations)
        suppressors = tuple(sorted(_suppressors_near(onset, observations)))
        symptom_scores, core_qualifying, secondary_qualifying, impairment_qualifying = _score_cycle_groups(
            pre_days, post_days, observations
        )
        core_symptom_count = len(core_qualifying)
        total_symptom_count = core_symptom_count + len(secondary_qualifying)
        impairment_count = len(impairment_qualifying)
        evaluable = pre_coverage >= 0.57 and post_coverage >= 0.57
        positive = evaluable and core_symptom_count >= 1 and total_symptom_count >= 5 and impairment_count >= 1
        subthreshold = evaluable and not positive and (core_symptom_count >= 1 or total_symptom_count >= 3 or impairment_count >= 1)
        cycles.append(
            _CycleSignal(
                onset=onset,
                pre_coverage=pre_coverage,
                post_coverage=post_coverage,
                positive=positive,
                subthreshold=subthreshold,
                core_symptom_count=core_symptom_count,
                total_symptom_count=total_symptom_count,
                impairment_count=impairment_count,
                symptom_scores=tuple(symptom_scores),
                qualifying_core_symptoms=tuple(core_qualifying),
                qualifying_secondary_symptoms=tuple(secondary_qualifying),
                qualifying_impairment_symptoms=tuple(impairment_qualifying),
                suppressors=suppressors,
            )
        )
    return cycles[-3:]


def _bleeding_start_dates(observations: list[ObservationEvent]) -> list[date]:
    bleeding_days = sorted(
        {
            _observed_day(event)
            for event in observations
            if event.tracker_code == "period_bleeding" and str(event.value) in _BLEED_STARTS
        }
    )
    return [day for day in bleeding_days if day - timedelta(days=1) not in bleeding_days]


def _coverage(days: list[date], observations: list[ObservationEvent]) -> float:
    if not days:
        return 0.0
    day_keys = {day.isoformat() for day in days}
    matched = {
        _observed_day(event).isoformat()
        for event in observations
        if _observed_day(event).isoformat() in day_keys
        and event.tracker_code in _DRSP_CODES
    }
    return len(matched) / len(days)


def _score_cycle_groups(
    pre_days: list[date],
    post_days: list[date],
    observations: list[ObservationEvent],
) -> tuple[list[PmddSymptomCycleScore], list[str], list[str], list[str]]:
    person_max = _person_max_rating(observations)
    symptom_scores: list[PmddSymptomCycleScore] = []
    core_qualifying: list[str] = []
    secondary_qualifying: list[str] = []
    impairment_qualifying: list[str] = []

    for group_code, codes in _ALL_GROUPS.items():
        pre_values = _group_day_scores(codes, pre_days, observations)
        post_values = _group_day_scores(codes, post_days, observations)
        pre_mean = _mean(pre_values) if pre_values else None
        post_mean = _mean(post_values) if post_values else None
        pre_max = int(max(pre_values)) if pre_values else None
        post_max = int(max(post_values)) if post_values else None
        severe_premenstrual_day_count = sum(1 for value in pre_values if value >= 4)
        relative_elevation = None
        qualifies = False
        if pre_values and post_values:
            denominator = max(person_max - 1.0, 1.0)
            relative_elevation = max(((_mean(pre_values) - _mean(post_values)) / denominator), 0.0)
            qualifies = (
                relative_elevation >= 0.30
                and max(post_values) <= 3
                and max(pre_values) >= 4
                and severe_premenstrual_day_count >= 2
            )
        score = PmddSymptomCycleScore(
            code=group_code,
            premenstrual_mean=round(pre_mean, 4) if pre_mean is not None else None,
            postmenstrual_mean=round(post_mean, 4) if post_mean is not None else None,
            premenstrual_max=pre_max,
            postmenstrual_max=post_max,
            severe_premenstrual_day_count=severe_premenstrual_day_count,
            relative_elevation=round(relative_elevation, 4) if relative_elevation is not None else None,
            qualifies=qualifies,
        )
        symptom_scores.append(score)
        if qualifies:
            if group_code in _CORE_GROUPS:
                core_qualifying.append(group_code)
            elif group_code in _SECONDARY_GROUPS:
                secondary_qualifying.append(group_code)
            elif group_code in _IMPAIRMENT_GROUPS:
                impairment_qualifying.append(group_code)
    return symptom_scores, core_qualifying, secondary_qualifying, impairment_qualifying


def _group_day_scores(codes: tuple[str, ...], days: list[date], observations: list[ObservationEvent]) -> list[float]:
    wanted = {day.isoformat() for day in days}
    by_day: dict[str, float] = {}
    for event in observations:
        if event.tracker_code not in codes:
            continue
        day_key = _observed_day(event).isoformat()
        if day_key not in wanted:
            continue
        score = _score(event.value)
        if score is None:
            continue
        by_day[day_key] = max(by_day.get(day_key, score), score)
    return [value for _, value in sorted(by_day.items())]


def _score(value: object) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        as_float = float(value)
        return as_float if 1.0 <= as_float <= 6.0 else None
    return None


def _suppressors_near(onset: date, observations: list[ObservationEvent]) -> set[str]:
    flags: set[str] = set()
    for event in observations:
        distance = abs((_observed_day(event) - onset).days)
        if distance > 60:
            continue
        if event.tracker_code == "postpartum_status" and event.value is True:
            flags.add("postpartum")
        if event.tracker_code == "lactation_status" and event.value is True:
            flags.add("lactation")
        if event.tracker_code == "psychotropic_medication_change" and event.value is True:
            flags.add("medication_change")
        if event.tracker_code == "pregnancy_test" and str(event.value) == "positive":
            flags.add("pregnancy")
    return flags


def _observed_day(event: ObservationEvent) -> date:
    return event.observed_on or event.observed_at.date()


def _person_max_rating(observations: list[ObservationEvent]) -> float:
    values = [_score(event.value) for event in observations if event.tracker_code in _DRSP_CODES]
    filtered = [value for value in values if value is not None]
    return max(filtered, default=6.0)


def _mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def _confidence_label(*, suppressed: bool, supporting_cycle_count: int, coverage: float) -> str:
    if suppressed:
        return "low"
    if supporting_cycle_count >= 3 and coverage >= 0.75:
        return "high"
    if supporting_cycle_count >= 2 and coverage >= 0.5:
        return "moderate"
    if coverage > 0:
        return "low"
    return "none"
