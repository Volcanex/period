"""Backend PCOS feature-pattern evaluation and reproducible backtesting.

This module implements a deliberately *non-diagnostic* analyzer that summarises
self-reported observations against the Rotterdam framework as restated by the
2023 International Evidence-based Guideline for the Assessment and Management of
Polycystic Ovary Syndrome (Teede et al., J Clin Endocrinol Metab 108[10]:2447).

It evaluates two of the three Rotterdam criteria from on-device self-report:

- Ovulatory dysfunction, via cycle-length derivation from period_bleeding onsets
  and the guideline's age-dependent thresholds:
    * Year 0-1 post-menarche: irregular cycles are normal pubertal transition.
    * Years 1-<3 post-menarche: cycle <21 or >45 days, or any cycle >90 days.
    * 3+ years post-menarche to perimenopause: cycle <21 or >35 days,
      fewer than 8 cycles per year, or any single cycle >90 days.
- Clinical hyperandrogenism, via persistent self-report of acne, unwanted
  terminal hair growth (hirsutism proxy), or scalp hair thinning. Biochemical
  androgens and the modified Ferriman-Gallwey examination are clinician-owned
  and intentionally out of scope.

The third Rotterdam feature - polycystic ovary morphology on ultrasound or
elevated AMH - is not self-trackable and is surfaced as a clinician-owned
follow-up rather than estimated.

Suppressors mirror guideline practice points: hormonal contraception (which
raises SHBG and suppresses gonadotrophin-dependent androgens, requiring a 3-
month washout), pregnancy, postpartum, lactation, and recent contraception
start/stop. Differential reminders flag conditions that mimic PCOS and must be
excluded clinically: thyroid disease, hyperprolactinemia, non-classic congenital
adrenal hyperplasia, Cushing syndrome, androgen-secreting tumors, primary
ovarian insufficiency, acromegaly, and iatrogenic causes.

The analyzer never returns a diagnosis. Output statuses describe whether
self-tracked features are consistent with a PCOS workup conversation.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

from core.contracts import (
    EvidenceReference,
    ObservationEvent,
    PcosCycleIrregularitySignal,
    PcosEvaluationResult,
    PcosHyperandrogenismSignal,
    PcosMetabolicSignal,
)

PCOS_ANALYZER_CODE = "pcos_feature_pattern_v1"
PCOS_ANALYZER_VERSION = "2026.05.11"

_GUIDELINE_EVIDENCE = EvidenceReference(
    source="Teede HJ et al. 2023 International Evidence-based Guideline for the Assessment and Management of Polycystic Ovary Syndrome (J Clin Endocrinol Metab 108:2447)",
    assumption="Self-report features map to Rotterdam ovulatory-dysfunction and clinical-hyperandrogenism criteria; PCOM and biochemical androgens remain clinician-owned.",
    confidence=0.78,
    version=PCOS_ANALYZER_VERSION,
    review_status="draft",
)

_ANALYZER_EVIDENCE = EvidenceReference(
    source="Period backend PCOS feature-pattern analyzer v1",
    assumption="Cycle-length derivation, persistent-feature thresholds, and contraceptive suppressor logic apply the 2023 guideline conservatively without collapsing uncertainty.",
    confidence=0.55,
    version=PCOS_ANALYZER_VERSION,
    review_status="draft",
)

_BLEED_ONSET_VALUES = {"light", "medium", "heavy"}
_SEVERITY_ORDER: tuple[str, ...] = ("none", "mild", "moderate", "severe")
_SEVERITY_RANK = {value: index for index, value in enumerate(_SEVERITY_ORDER)}
_HORMONAL_CONTRACEPTION_METHODS = {"pill", "iud", "implant", "injection", "patch", "ring"}
_PROGESTIN_ONLY_METHODS = {"iud", "implant", "injection"}

_DIFFERENTIAL_REMINDERS: tuple[str, ...] = (
    "thyroid_dysfunction",
    "hyperprolactinemia",
    "non_classic_congenital_adrenal_hyperplasia",
    "cushing_syndrome",
    "androgen_secreting_tumor",
    "primary_ovarian_insufficiency",
    "acromegaly",
    "iatrogenic_androgen_exposure",
)

_HYPERANDROGENIC_TRACKERS: dict[str, str] = {
    "acne_severity": "acne",
    "hair_growth": "hirsutism",
    "hair_thinning": "scalp_thinning",
}


@dataclass(frozen=True)
class PcosBacktestCase:
    case_id: str
    subject_id: str
    expected_status: str
    years_since_menarche: float | None
    observations: tuple[ObservationEvent, ...]


@dataclass(frozen=True)
class PcosBacktestFold:
    case_id: str
    expected_status: str
    predicted_status: str
    status_match: bool
    confidence: str
    age_group_used: str
    rotterdam_self_report_feature_count: int
    meets_irregularity_rule: bool
    meets_hyperandrogenism_rule: bool


@dataclass(frozen=True)
class PcosBacktestSummary:
    fold_count: int
    exact_match_rate: float
    folds: tuple[PcosBacktestFold, ...]


def load_pcos_backtest_cases(rows: list[dict]) -> list[PcosBacktestCase]:
    cases: list[PcosBacktestCase] = []
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
            PcosBacktestCase(
                case_id=row["case_id"],
                subject_id=row["subject_id"],
                expected_status=row["expected_status"],
                years_since_menarche=row.get("years_since_menarche"),
                observations=observations,
            )
        )
    return cases


def load_pcos_backtest_fixture(path: Path | None = None) -> list[PcosBacktestCase]:
    fixture_path = path or Path(__file__).resolve().parents[2] / "tests" / "data" / "pcos_backtest_cases.json"
    return load_pcos_backtest_cases(json.loads(fixture_path.read_text(encoding="utf-8")))


def backtest_pcos_cases(cases: list[PcosBacktestCase]) -> PcosBacktestSummary:
    folds: list[PcosBacktestFold] = []
    for case in cases:
        result = evaluate_pcos(
            case.subject_id,
            list(case.observations),
            years_since_menarche=case.years_since_menarche,
        )
        folds.append(
            PcosBacktestFold(
                case_id=case.case_id,
                expected_status=case.expected_status,
                predicted_status=result.status,
                status_match=result.status == case.expected_status,
                confidence=result.confidence,
                age_group_used=result.age_group_used,
                rotterdam_self_report_feature_count=result.rotterdam_self_report_feature_count,
                meets_irregularity_rule=result.meets_irregularity_rule,
                meets_hyperandrogenism_rule=result.meets_hyperandrogenism_rule,
            )
        )
    exact_match_rate = sum(1 for fold in folds if fold.status_match) / len(folds) if folds else 0.0
    return PcosBacktestSummary(
        fold_count=len(folds),
        exact_match_rate=exact_match_rate,
        folds=tuple(folds),
    )


def pcos_backtest_summary_to_dict(summary: PcosBacktestSummary) -> dict:
    by_expected: dict[str, int] = {}
    by_predicted: dict[str, int] = {}
    for fold in summary.folds:
        by_expected[fold.expected_status] = by_expected.get(fold.expected_status, 0) + 1
        by_predicted[fold.predicted_status] = by_predicted.get(fold.predicted_status, 0) + 1
    return {
        "analyzer_code": PCOS_ANALYZER_CODE,
        "analyzer_version": PCOS_ANALYZER_VERSION,
        "fold_count": summary.fold_count,
        "exact_match_rate": round(summary.exact_match_rate, 4),
        "expected_status_counts": by_expected,
        "predicted_status_counts": by_predicted,
        "folds": [asdict(fold) for fold in summary.folds],
    }


def evaluate_pcos(
    subject_id: str,
    observations: list[ObservationEvent],
    *,
    years_since_menarche: float | None = None,
    evaluated_at: datetime | None = None,
    evaluation_window_days: int = 365,
) -> PcosEvaluationResult:
    generated_at = (evaluated_at or datetime.now(UTC)).astimezone(UTC)
    window_end = generated_at.date()
    window_start = window_end - timedelta(days=evaluation_window_days)
    ordered = sorted(observations, key=lambda event: (_observed_day(event), event.observed_at))
    in_window = [event for event in ordered if window_start <= _observed_day(event) <= window_end]

    age_group, age_rule, adolescent_required = _classify_age(years_since_menarche)
    suppressors = _collect_suppressors(in_window, window_end)
    cycle_signal = _cycle_signal(in_window, age_rule)
    hyperandrogenism_signal = _hyperandrogenism_signal(in_window)
    metabolic_signal = _metabolic_signal(in_window)

    rotterdam_count = (1 if cycle_signal.meets_irregularity_rule else 0) + (
        1 if hyperandrogenism_signal.meets_hyperandrogenism_rule else 0
    )

    status, pcom_could_resolve = _resolve_status(
        cycle_signal=cycle_signal,
        hyperandrogenism_signal=hyperandrogenism_signal,
        age_group=age_group,
        rotterdam_count=rotterdam_count,
        suppressors=suppressors,
    )

    confidence = _confidence_label(
        cycle_signal=cycle_signal,
        hyperandrogenism_signal=hyperandrogenism_signal,
        suppressors=suppressors,
        age_group=age_group,
    )

    summary = _summary(
        status=status,
        age_group=age_group,
        rotterdam_count=rotterdam_count,
        cycle_signal=cycle_signal,
        hyperandrogenism_signal=hyperandrogenism_signal,
    )

    recommended_actions = _recommended_actions(
        status=status,
        age_group=age_group,
        cycle_signal=cycle_signal,
        hyperandrogenism_signal=hyperandrogenism_signal,
        suppressors=suppressors,
        pcom_could_resolve=pcom_could_resolve,
        metabolic_signal=metabolic_signal,
    )

    evidence_summary = (
        f"{cycle_signal.observed_cycle_count} cycle(s) derived · "
        f"{hyperandrogenism_signal.persistent_feature_count} hyperandrogenic feature(s) · "
        f"{'suppressors: ' + ', '.join(suppressors) if suppressors else 'no major suppressors'}"
    )

    return PcosEvaluationResult(
        analyzer_code=PCOS_ANALYZER_CODE,
        analyzer_version=PCOS_ANALYZER_VERSION,
        subject_id=subject_id,
        generated_at=generated_at,
        evaluation_window_start=window_start,
        evaluation_window_end=window_end,
        status=status,
        confidence=confidence,
        age_group_used=age_group,
        cycle_irregularity=cycle_signal,
        hyperandrogenism=hyperandrogenism_signal,
        metabolic_context=metabolic_signal,
        rotterdam_self_report_feature_count=rotterdam_count,
        meets_irregularity_rule=cycle_signal.meets_irregularity_rule,
        meets_hyperandrogenism_rule=hyperandrogenism_signal.meets_hyperandrogenism_rule,
        pcom_assessment_could_resolve=pcom_could_resolve,
        adolescent_both_features_required=adolescent_required,
        suppressors=suppressors,
        differential_reminders=list(_DIFFERENTIAL_REMINDERS),
        summary=summary,
        evidence_summary=evidence_summary,
        recommended_actions=recommended_actions,
        evidence=[_GUIDELINE_EVIDENCE, _ANALYZER_EVIDENCE],
    )


def _classify_age(years_since_menarche: float | None) -> tuple[str, str, bool]:
    if years_since_menarche is None:
        return "unknown", "default_adult", False
    if years_since_menarche < 1:
        return "adolescent_pubertal", "pubertal_transition", True
    if years_since_menarche < 3:
        return "adolescent_post", "early_post_menarche", True
    return "adult", "adult", False


def _cycle_signal(events: list[ObservationEvent], age_rule: str) -> PcosCycleIrregularitySignal:
    bleed_onsets = _bleeding_onsets(events)
    self_reports = _self_reported_regularity(events)
    self_reported = self_reports[-1] if self_reports else None

    cycle_lengths: list[int] = []
    for previous, current in zip(bleed_onsets, bleed_onsets[1:]):
        delta = (current - previous).days
        if delta > 0:
            cycle_lengths.append(delta)

    longest = max(cycle_lengths) if cycle_lengths else None
    shortest = min(cycle_lengths) if cycle_lengths else None
    cycles_per_year_estimate: float | None = None
    if cycle_lengths:
        mean_length = sum(cycle_lengths) / len(cycle_lengths)
        cycles_per_year_estimate = round(365.25 / mean_length, 2) if mean_length > 0 else None

    if age_rule == "pubertal_transition":
        return PcosCycleIrregularitySignal(
            classification="pubertal_transition",
            age_rule_applied=age_rule,
            observed_cycle_count=len(cycle_lengths),
            observed_cycle_lengths=cycle_lengths,
            longest_cycle_days=longest,
            shortest_cycle_days=shortest,
            cycles_per_year_estimate=cycles_per_year_estimate,
            self_reported_regularity=self_reported,
            fallback_to_self_report=False,
            meets_irregularity_rule=False,
            rationale="First year post-menarche; irregular cycles are part of normal pubertal transition per 2023 IEG recommendation 1.1.1.",
        )

    if len(cycle_lengths) >= 1:
        classification, meets_rule, rationale = _classify_from_lengths(cycle_lengths, age_rule)
        return PcosCycleIrregularitySignal(
            classification=classification,
            age_rule_applied=age_rule,
            observed_cycle_count=len(cycle_lengths),
            observed_cycle_lengths=cycle_lengths,
            longest_cycle_days=longest,
            shortest_cycle_days=shortest,
            cycles_per_year_estimate=cycles_per_year_estimate,
            self_reported_regularity=self_reported,
            fallback_to_self_report=False,
            meets_irregularity_rule=meets_rule,
            rationale=rationale,
        )

    # Fall back to self-report when there are too few derived cycles.
    if self_reported in {"regular"}:
        return PcosCycleIrregularitySignal(
            classification="regular",
            age_rule_applied=age_rule,
            observed_cycle_count=len(cycle_lengths),
            observed_cycle_lengths=cycle_lengths,
            longest_cycle_days=longest,
            shortest_cycle_days=shortest,
            cycles_per_year_estimate=cycles_per_year_estimate,
            self_reported_regularity=self_reported,
            fallback_to_self_report=True,
            meets_irregularity_rule=False,
            rationale="Insufficient bleeding history to derive cycle lengths; user-reported cycle_regularity is 'regular'.",
        )
    if self_reported in {"variable", "infrequent"}:
        return PcosCycleIrregularitySignal(
            classification="irregular",
            age_rule_applied=age_rule,
            observed_cycle_count=len(cycle_lengths),
            observed_cycle_lengths=cycle_lengths,
            longest_cycle_days=longest,
            shortest_cycle_days=shortest,
            cycles_per_year_estimate=cycles_per_year_estimate,
            self_reported_regularity=self_reported,
            fallback_to_self_report=True,
            meets_irregularity_rule=True,
            rationale="Insufficient bleeding history to derive cycle lengths; user reports variable/infrequent cycles.",
        )
    if self_reported == "absent":
        return PcosCycleIrregularitySignal(
            classification="amenorrhea",
            age_rule_applied=age_rule,
            observed_cycle_count=len(cycle_lengths),
            observed_cycle_lengths=cycle_lengths,
            longest_cycle_days=longest,
            shortest_cycle_days=shortest,
            cycles_per_year_estimate=cycles_per_year_estimate,
            self_reported_regularity=self_reported,
            fallback_to_self_report=True,
            meets_irregularity_rule=True,
            rationale="User reports absent menses (amenorrhea); evaluate underlying cause clinically.",
        )

    return PcosCycleIrregularitySignal(
        classification="insufficient_data",
        age_rule_applied=age_rule,
        observed_cycle_count=len(cycle_lengths),
        observed_cycle_lengths=cycle_lengths,
        longest_cycle_days=longest,
        shortest_cycle_days=shortest,
        cycles_per_year_estimate=cycles_per_year_estimate,
        self_reported_regularity=self_reported,
        fallback_to_self_report=False,
        meets_irregularity_rule=False,
        rationale="Not enough bleeding history or self-reported cycle context to classify cycle regularity.",
    )


def _classify_from_lengths(lengths: list[int], age_rule: str) -> tuple[str, bool, str]:
    longest = max(lengths)
    shortest = min(lengths)
    cycle_count = len(lengths)

    if longest > 90:
        return (
            "irregular",
            True,
            f"Any single cycle >90 days (observed {longest}) qualifies as oligo/anovulation per 2023 IEG.",
        )

    if age_rule == "early_post_menarche":
        if shortest < 21 or longest > 45:
            return (
                "irregular",
                True,
                f"Cycle <21 or >45 days within 1-3 years post-menarche (observed {shortest}-{longest}).",
            )
        return (
            "regular",
            False,
            f"Cycle lengths {shortest}-{longest} within the 21-45 day window for 1-3 years post-menarche.",
        )

    # Adult / default-adult rule.
    if shortest < 21 or longest > 35:
        return (
            "irregular",
            True,
            f"Cycle <21 or >35 days for an adult cycle (observed {shortest}-{longest}).",
        )
    # <8 cycles per year proxy: if the average cycle length implies <8 over the
    # observed span we treat this as oligomenorrhea. We use a conservative
    # threshold of mean length > 45 days, which is roughly equivalent.
    mean_length = sum(lengths) / cycle_count
    if mean_length > 45:
        return (
            "irregular",
            True,
            f"Mean cycle length {mean_length:.1f} days implies <8 cycles per year.",
        )
    return (
        "regular",
        False,
        f"Cycle lengths {shortest}-{longest} within the 21-35 day adult window.",
    )


def _hyperandrogenism_signal(events: list[ObservationEvent]) -> PcosHyperandrogenismSignal:
    severity_counts: dict[str, dict[str, int]] = {
        tracker: {value: 0 for value in _SEVERITY_ORDER} for tracker in _HYPERANDROGENIC_TRACKERS
    }
    max_severity: dict[str, str | None] = {tracker: None for tracker in _HYPERANDROGENIC_TRACKERS}
    for event in events:
        if event.tracker_code not in _HYPERANDROGENIC_TRACKERS:
            continue
        if not isinstance(event.value, str):
            continue
        value = event.value.lower()
        if value not in _SEVERITY_RANK:
            continue
        severity_counts[event.tracker_code][value] += 1
        current = max_severity[event.tracker_code]
        if current is None or _SEVERITY_RANK[value] > _SEVERITY_RANK[current]:
            max_severity[event.tracker_code] = value

    qualifying: list[str] = []

    def _persistent(tracker: str) -> bool:
        moderate = severity_counts[tracker]["moderate"]
        severe = severity_counts[tracker]["severe"]
        if severe >= 1:
            return True
        return moderate >= 2

    acne_persistent = _persistent("acne_severity")
    hirsutism_persistent = _persistent("hair_growth")
    scalp_thinning_persistent = _persistent("hair_thinning")

    if acne_persistent:
        qualifying.append("acne_persistent")
    if hirsutism_persistent:
        qualifying.append("hirsutism_self_reported")
    if scalp_thinning_persistent:
        qualifying.append("scalp_hair_thinning")

    persistent_count = sum([acne_persistent, hirsutism_persistent, scalp_thinning_persistent])
    meets_rule = persistent_count >= 1

    if meets_rule:
        rationale = (
            "At least one persistent clinical hyperandrogenism feature self-reported "
            "(persistent = severe at any point, or moderate on >=2 days)."
        )
    elif any(max_severity[tracker] in {"mild", "moderate", "severe"} for tracker in _HYPERANDROGENIC_TRACKERS):
        rationale = "Some androgenic features reported but did not meet the persistence threshold."
    else:
        rationale = "No persistent clinical hyperandrogenism feature reported in the window."

    return PcosHyperandrogenismSignal(
        acne_severity_max=max_severity["acne_severity"],
        unwanted_hair_growth_max=max_severity["hair_growth"],
        scalp_hair_thinning_max=max_severity["hair_thinning"],
        acne_persistent=acne_persistent,
        hirsutism_persistent=hirsutism_persistent,
        scalp_thinning_persistent=scalp_thinning_persistent,
        qualifying_features=qualifying,
        persistent_feature_count=persistent_count,
        meets_hyperandrogenism_rule=meets_rule,
        rationale=rationale,
    )


def _metabolic_signal(events: list[ObservationEvent]) -> PcosMetabolicSignal:
    weights: list[float] = []
    weight_first: float | None = None
    weight_last: float | None = None
    acanthosis = False
    insulin_notes = 0
    glucose_notes = 0
    lipid_notes = 0
    flags: list[str] = []
    weighed_events = [event for event in events if event.tracker_code == "weight"]
    for event in weighed_events:
        try:
            value = float(event.value)
        except (TypeError, ValueError):
            continue
        weights.append(value)
        if weight_first is None:
            weight_first = value
        weight_last = value
    for event in events:
        if event.tracker_code == "acanthosis_nigricans" and bool(event.value):
            acanthosis = True
        elif event.tracker_code == "insulin_metabolic_note":
            insulin_notes += 1
        elif event.tracker_code == "glucose_lab_note":
            glucose_notes += 1
        elif event.tracker_code == "lipid_note":
            lipid_notes += 1
    delta: float | None = None
    if weight_first is not None and weight_last is not None:
        delta = round(weight_last - weight_first, 2)
    if acanthosis:
        flags.append("acanthosis_nigricans_reported_insulin_resistance_marker")
    if insulin_notes or glucose_notes or lipid_notes:
        flags.append("metabolic_notes_logged")
    if weights:
        flags.append("weight_history_available")
    return PcosMetabolicSignal(
        acanthosis_nigricans_reported=acanthosis,
        weight_observation_count=len(weights),
        weight_kg_min=min(weights) if weights else None,
        weight_kg_max=max(weights) if weights else None,
        weight_kg_delta=delta,
        insulin_metabolic_note_count=insulin_notes,
        glucose_lab_note_count=glucose_notes,
        lipid_note_count=lipid_notes,
        flags=flags,
    )


def _collect_suppressors(events: list[ObservationEvent], window_end: date) -> list[str]:
    suppressors: set[str] = set()
    contraception_use: str | None = None
    contraception_use_at: datetime | None = None
    contraception_start: date | None = None
    contraception_stop: date | None = None
    for event in events:
        day = _observed_day(event)
        if event.tracker_code == "pregnancy_test" and event.value == "positive":
            suppressors.add("pregnancy")
        elif event.tracker_code == "postpartum_status" and bool(event.value):
            suppressors.add("postpartum")
        elif event.tracker_code == "lactation_status" and bool(event.value):
            suppressors.add("lactation")
        elif event.tracker_code == "contraception_use":
            if contraception_use_at is None or event.observed_at >= contraception_use_at:
                contraception_use = event.value if isinstance(event.value, str) else None
                contraception_use_at = event.observed_at
        elif event.tracker_code == "contraception_start":
            try:
                contraception_start = date.fromisoformat(str(event.value))
            except ValueError:
                pass
        elif event.tracker_code == "contraception_stop":
            try:
                contraception_stop = date.fromisoformat(str(event.value))
            except ValueError:
                pass

    if contraception_use == "pill":
        suppressors.add("combined_oral_contraceptive")
    elif contraception_use in _HORMONAL_CONTRACEPTION_METHODS:
        if contraception_use in _PROGESTIN_ONLY_METHODS:
            suppressors.add("progestin_only_contraception")
        else:
            suppressors.add("hormonal_contraception")
    if contraception_stop and (window_end - contraception_stop).days <= 90:
        suppressors.add("recent_contraception_withdrawal_within_3_months")
    if contraception_start and (window_end - contraception_start).days <= 180:
        suppressors.add("recent_contraception_start_within_6_months")
    return sorted(suppressors)


def _resolve_status(
    *,
    cycle_signal: PcosCycleIrregularitySignal,
    hyperandrogenism_signal: PcosHyperandrogenismSignal,
    age_group: str,
    rotterdam_count: int,
    suppressors: list[str],
) -> tuple[str, bool]:
    if suppressors:
        return "suppressed", False
    if cycle_signal.classification == "pubertal_transition":
        # Within 1y post-menarche only the hyperandrogenism feature is interpretable.
        if hyperandrogenism_signal.meets_hyperandrogenism_rule:
            return "features_partial", False
        return "insufficient_data", False
    if (
        cycle_signal.classification == "insufficient_data"
        and not hyperandrogenism_signal.meets_hyperandrogenism_rule
    ):
        return "insufficient_data", False
    if age_group in {"adolescent_pubertal", "adolescent_post"}:
        if rotterdam_count == 2:
            return "features_present", False
        if rotterdam_count == 1:
            # Adolescents require BOTH features; ultrasound/AMH not used.
            return "features_partial", False
        return "features_absent", False
    # Adult / unknown age (treated as adult by default).
    if rotterdam_count == 2:
        return "features_present", False
    if rotterdam_count == 1:
        return "features_partial", True
    return "features_absent", False


def _confidence_label(
    *,
    cycle_signal: PcosCycleIrregularitySignal,
    hyperandrogenism_signal: PcosHyperandrogenismSignal,
    suppressors: list[str],
    age_group: str,
) -> str:
    if suppressors:
        return "low"
    cycle_count = cycle_signal.observed_cycle_count
    rich_cycle = cycle_count >= 6 and not cycle_signal.fallback_to_self_report
    moderate_cycle = cycle_count >= 3 and not cycle_signal.fallback_to_self_report
    persistent_features = hyperandrogenism_signal.persistent_feature_count
    if rich_cycle and persistent_features >= 1 and age_group != "unknown":
        return "high"
    if moderate_cycle or persistent_features >= 1:
        return "moderate"
    if cycle_signal.fallback_to_self_report or cycle_count >= 1:
        return "low"
    return "none"


def _summary(
    *,
    status: str,
    age_group: str,
    rotterdam_count: int,
    cycle_signal: PcosCycleIrregularitySignal,
    hyperandrogenism_signal: PcosHyperandrogenismSignal,
) -> str:
    if status == "suppressed":
        return (
            "PCOS feature evaluation is suppressed because pregnancy, postpartum, lactation, or hormonal "
            "contraception confounds cycle and androgen signals; per 2023 IEG, biochemical androgens require "
            "a 3-month combined-oral-contraceptive washout to assess reliably."
        )
    if status == "insufficient_data":
        return "Not enough tracked bleeding history or feature reporting to evaluate PCOS-style features yet."
    if status == "features_present":
        if age_group in {"adolescent_pubertal", "adolescent_post"}:
            return (
                "Both irregular cycles and self-reported clinical hyperandrogenism are present, which the "
                "2023 IEG flags as the adolescent feature pair warranting clinical PCOS assessment."
            )
        return (
            "Two of the Rotterdam features (ovulatory dysfunction and clinical hyperandrogenism) are present in "
            "self-report; clinician evaluation should rule out mimics before any diagnosis."
        )
    if status == "features_partial":
        if cycle_signal.meets_irregularity_rule and not hyperandrogenism_signal.meets_hyperandrogenism_rule:
            return "Cycle irregularity is the only Rotterdam feature observed; clinician workup may add ultrasound or AMH and biochemical androgens."
        return "Clinical hyperandrogenism features are present without a clear cycle-irregularity signal; clinician workup may add ultrasound or AMH and biochemical androgens."
    return "No persistent Rotterdam features observed in the evaluation window."


def _recommended_actions(
    *,
    status: str,
    age_group: str,
    cycle_signal: PcosCycleIrregularitySignal,
    hyperandrogenism_signal: PcosHyperandrogenismSignal,
    suppressors: list[str],
    pcom_could_resolve: bool,
    metabolic_signal: PcosMetabolicSignal,
) -> list[str]:
    actions: list[str] = []
    if status == "suppressed":
        actions.append(
            "Discuss tracked context (pregnancy, postpartum, lactation, contraception) with a clinician; "
            "a combined-oral-contraceptive washout of at least 3 months is required before biochemical "
            "androgen testing is reliable."
        )
        return actions
    if status == "insufficient_data":
        actions.append("Continue logging period_bleeding, acne_severity, hair_growth, and hair_thinning to build evaluable history.")
        return actions
    if status == "features_present":
        actions.append("Discuss the feature pattern with a clinician; only a clinician can diagnose PCOS and exclude mimics.")
    elif status == "features_partial":
        actions.append("Discuss the partial feature pattern with a clinician; a single feature alone does not establish PCOS.")
    else:
        actions.append("Continue routine tracking; current self-report does not show Rotterdam features.")

    if age_group in {"adolescent_pubertal", "adolescent_post"}:
        actions.append(
            "Adolescent assessment per 2023 IEG requires both irregular cycles and hyperandrogenism; ultrasound and AMH are not used."
        )
    elif pcom_could_resolve:
        actions.append(
            "Clinician may use pelvic ultrasound or AMH to assess polycystic ovary morphology as the third Rotterdam criterion (adults only)."
        )

    if hyperandrogenism_signal.meets_hyperandrogenism_rule:
        actions.append(
            "Standard biochemical workup includes total/free testosterone (LC-MS preferred), SHBG, and free androgen index; "
            "this analyzer does not perform that workup."
        )
    actions.append(
        "Exclude differential diagnoses with a clinician: thyroid disease, hyperprolactinemia, non-classic congenital adrenal hyperplasia, "
        "Cushing syndrome, androgen-secreting tumors, primary ovarian insufficiency, acromegaly, and iatrogenic causes."
    )
    if metabolic_signal.acanthosis_nigricans_reported:
        actions.append("Acanthosis nigricans is a marker of insulin resistance; discuss metabolic screening with a clinician.")
    return actions


def _bleeding_onsets(events: list[ObservationEvent]) -> list[date]:
    days = sorted({
        _observed_day(event)
        for event in events
        if event.tracker_code == "period_bleeding"
        and isinstance(event.value, str)
        and event.value in _BLEED_ONSET_VALUES
    })
    onsets: list[date] = []
    last_day: date | None = None
    for day in days:
        if last_day is None or (day - last_day).days > 1:
            onsets.append(day)
        last_day = day
    return onsets


def _self_reported_regularity(events: list[ObservationEvent]) -> list[str]:
    return [
        event.value
        for event in events
        if event.tracker_code == "cycle_regularity" and isinstance(event.value, str)
    ]


def _observed_day(event: ObservationEvent) -> date:
    return event.observed_on or event.observed_at.date()
