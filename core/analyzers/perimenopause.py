"""Backend perimenopause staging analyzer aligned to STRAW+10.

This module implements a reproducible, non-diagnostic staging analyzer for the
menopausal transition based on the Stages of Reproductive Aging Workshop +10
(STRAW+10) executive summary (Harlow SD, Gass M, Hall JE, et al., J Clin
Endocrinol Metab 97[4]:1159, 2012). STRAW+10 stages reproductive aging from
-5 (early reproductive) through +2 (late postmenopause) around the Final
Menstrual Period (FMP). This analyzer self-tracks the following stages from
bleeding history and self-reported symptoms:

- ``minus_3b`` - Late reproductive, regular cycles, no symptoms.
- ``minus_3a`` - Late reproductive with subtle cycle changes (shorter cycles,
  self-reported pattern change).
- ``minus_2`` - Early menopausal transition: persistent >=7-day difference in
  the length of consecutive cycles, recurring within 10 cycles.
- ``minus_1`` - Late menopausal transition: amenorrhea of 60 days or longer.
- ``plus_1a`` - 12-24 months since the last menstrual period (FMP confirmed
  retroactively after 12 months of amenorrhea).
- ``plus_1b`` - 24-36 months since FMP.
- ``plus_1c`` - 36-96 months since FMP, the stabilization phase.
- ``plus_2`` - Late postmenopause: more than ~96 months since FMP.

STRAW+10 explicitly limits applicability: women who have had a hysterectomy or
endometrial ablation cannot be staged by menstrual criteria, and women on
hormonal contraception have suppressed cycles. PCOS and hypothalamic
amenorrhea also fall outside STRAW+10's bleeding-based criteria. This
analyzer flags those conditions as suppressors or inapplicability rather than
staging through them.

The analyzer never returns a diagnosis. It surfaces a STRAW+10 stage estimate
from self-tracked observations for clinician-conversation framing.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

from core.contracts import (
    EvidenceReference,
    ObservationEvent,
    PerimenopauseCycleSignal,
    PerimenopauseEvaluationResult,
    PerimenopauseSymptomSignal,
)

PERIMENOPAUSE_ANALYZER_CODE = "perimenopause_straw10_v1"
PERIMENOPAUSE_ANALYZER_VERSION = "2026.05.12"

_STRAW_EVIDENCE = EvidenceReference(
    source="Harlow SD, Gass M, Hall JE, et al. Executive summary of the Stages of Reproductive Aging Workshop +10 (J Clin Endocrinol Metab 97:1159; Menopause 19:387; Climacteric 15:105; 2012)",
    assumption="Self-tracked bleeding history and symptom severity can be mapped onto STRAW+10 menstrual criteria for stages -3a through +2 within the system's stated applicability limits.",
    confidence=0.82,
    version=PERIMENOPAUSE_ANALYZER_VERSION,
    review_status="draft",
)

_ANALYZER_EVIDENCE = EvidenceReference(
    source="Period backend perimenopause STRAW+10 staging analyzer v1",
    assumption="Cycle-pair variability, amenorrhea-window measurement, and symptom-persistence thresholds conservatively reproduce STRAW+10 without claiming endocrine biomarker access.",
    confidence=0.60,
    version=PERIMENOPAUSE_ANALYZER_VERSION,
    review_status="draft",
)

_BLEED_ONSET_VALUES = {"light", "medium", "heavy"}
_HORMONAL_CONTRACEPTION_METHODS = {"pill", "iud", "implant", "injection", "patch", "ring"}
_PROGESTIN_ONLY_METHODS = {"iud", "implant", "injection"}

_SEVERITY_ORDER: tuple[str, ...] = ("none", "mild", "moderate", "severe")
_SEVERITY_RANK = {value: index for index, value in enumerate(_SEVERITY_ORDER)}

_SYMPTOM_TRACKERS: tuple[str, ...] = ("hot_flashes", "night_sweats", "vaginal_dryness")

_DIFFERENTIAL_REMINDERS: tuple[str, ...] = (
    "thyroid_dysfunction",
    "hyperprolactinemia",
    "primary_ovarian_insufficiency_if_under_40",
    "hypothalamic_amenorrhea",
    "asherman_syndrome",
    "endometrial_pathology_for_abnormal_bleeding",
    "iatrogenic_hormonal_exposure",
)


@dataclass(frozen=True)
class PerimenopauseBacktestCase:
    case_id: str
    subject_id: str
    expected_status: str
    expected_stage: str
    chronological_age: float | None
    post_hysterectomy: bool
    known_fmp_date: date | None
    observations: tuple[ObservationEvent, ...]


@dataclass(frozen=True)
class PerimenopauseBacktestFold:
    case_id: str
    expected_status: str
    predicted_status: str
    expected_stage: str
    predicted_stage: str
    status_match: bool
    stage_match: bool
    confidence: str


@dataclass(frozen=True)
class PerimenopauseBacktestSummary:
    fold_count: int
    exact_status_match_rate: float
    exact_stage_match_rate: float
    folds: tuple[PerimenopauseBacktestFold, ...]


def load_perimenopause_backtest_cases(rows: list[dict]) -> list[PerimenopauseBacktestCase]:
    cases: list[PerimenopauseBacktestCase] = []
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
            PerimenopauseBacktestCase(
                case_id=row["case_id"],
                subject_id=row["subject_id"],
                expected_status=row["expected_status"],
                expected_stage=row["expected_stage"],
                chronological_age=row.get("chronological_age"),
                post_hysterectomy=bool(row.get("post_hysterectomy", False)),
                known_fmp_date=date.fromisoformat(row["known_fmp_date"]) if row.get("known_fmp_date") else None,
                observations=observations,
            )
        )
    return cases


def load_perimenopause_backtest_fixture(path: Path | None = None) -> list[PerimenopauseBacktestCase]:
    fixture_path = path or Path(__file__).resolve().parents[2] / "tests" / "data" / "perimenopause_backtest_cases.json"
    return load_perimenopause_backtest_cases(json.loads(fixture_path.read_text(encoding="utf-8")))


def backtest_perimenopause_cases(cases: list[PerimenopauseBacktestCase]) -> PerimenopauseBacktestSummary:
    folds: list[PerimenopauseBacktestFold] = []
    for case in cases:
        result = evaluate_perimenopause(
            case.subject_id,
            list(case.observations),
            chronological_age=case.chronological_age,
            post_hysterectomy=case.post_hysterectomy,
            known_fmp_date=case.known_fmp_date,
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
    status_rate = sum(1 for fold in folds if fold.status_match) / len(folds) if folds else 0.0
    stage_rate = sum(1 for fold in folds if fold.stage_match) / len(folds) if folds else 0.0
    return PerimenopauseBacktestSummary(
        fold_count=len(folds),
        exact_status_match_rate=status_rate,
        exact_stage_match_rate=stage_rate,
        folds=tuple(folds),
    )


def perimenopause_backtest_summary_to_dict(summary: PerimenopauseBacktestSummary) -> dict:
    by_expected_status: dict[str, int] = {}
    by_predicted_status: dict[str, int] = {}
    by_expected_stage: dict[str, int] = {}
    by_predicted_stage: dict[str, int] = {}
    for fold in summary.folds:
        by_expected_status[fold.expected_status] = by_expected_status.get(fold.expected_status, 0) + 1
        by_predicted_status[fold.predicted_status] = by_predicted_status.get(fold.predicted_status, 0) + 1
        by_expected_stage[fold.expected_stage] = by_expected_stage.get(fold.expected_stage, 0) + 1
        by_predicted_stage[fold.predicted_stage] = by_predicted_stage.get(fold.predicted_stage, 0) + 1
    return {
        "analyzer_code": PERIMENOPAUSE_ANALYZER_CODE,
        "analyzer_version": PERIMENOPAUSE_ANALYZER_VERSION,
        "fold_count": summary.fold_count,
        "exact_status_match_rate": round(summary.exact_status_match_rate, 4),
        "exact_stage_match_rate": round(summary.exact_stage_match_rate, 4),
        "expected_status_counts": by_expected_status,
        "predicted_status_counts": by_predicted_status,
        "expected_stage_counts": by_expected_stage,
        "predicted_stage_counts": by_predicted_stage,
        "folds": [asdict(fold) for fold in summary.folds],
    }


def evaluate_perimenopause(
    subject_id: str,
    observations: list[ObservationEvent],
    *,
    chronological_age: float | None = None,
    post_hysterectomy: bool = False,
    known_fmp_date: date | None = None,
    evaluated_at: datetime | None = None,
    evaluation_window_days: int = 540,
) -> PerimenopauseEvaluationResult:
    generated_at = (evaluated_at or datetime.now(UTC)).astimezone(UTC)
    window_end = generated_at.date()
    window_start = window_end - timedelta(days=evaluation_window_days)
    ordered = sorted(observations, key=lambda event: (_observed_day(event), event.observed_at))
    in_window = [event for event in ordered if window_start <= _observed_day(event) <= window_end]

    inapplicability: list[str] = []
    if post_hysterectomy:
        inapplicability.append("post_hysterectomy_or_ablation")

    suppressors = _collect_suppressors(in_window, window_end)

    cycle_signal = _cycle_signal(in_window, generated_at.date())
    symptom_signal = _symptom_signal(in_window)

    fmp_candidate, months_since_last_bleed = _fmp_candidate(
        cycle_signal=cycle_signal,
        known_fmp_date=known_fmp_date,
        window_end=window_end,
    )
    fmp_confirmed = (
        known_fmp_date is not None or cycle_signal.amenorrhea_365_plus_days_observed
    )

    if inapplicability:
        status = "inapplicable"
        stage = "indeterminate"
        confidence = "low"
    elif suppressors:
        status = "suppressed"
        stage = "indeterminate"
        confidence = "low"
    else:
        stage = _stage_from_signals(
            cycle_signal=cycle_signal,
            months_since_last_bleed=months_since_last_bleed,
            fmp_confirmed=fmp_confirmed,
        )
        status = _status_from_stage(stage, cycle_signal=cycle_signal)
        confidence = _confidence(
            stage=stage,
            cycle_signal=cycle_signal,
            symptom_signal=symptom_signal,
            fmp_confirmed=fmp_confirmed,
        )

    differential_reminders = list(_DIFFERENTIAL_REMINDERS)
    if chronological_age is not None and chronological_age < 40 and stage in {"minus_1", "plus_1a", "plus_1b", "plus_1c", "plus_2"}:
        differential_reminders.append("premature_ovarian_insufficiency_if_under_40")

    summary = _summary(
        status=status,
        stage=stage,
        cycle_signal=cycle_signal,
        symptom_signal=symptom_signal,
        months_since_last_bleed=months_since_last_bleed,
    )
    recommended_actions = _recommended_actions(
        status=status,
        stage=stage,
        cycle_signal=cycle_signal,
        symptom_signal=symptom_signal,
        chronological_age=chronological_age,
        suppressors=suppressors,
    )
    evidence_summary = (
        f"{cycle_signal.observed_cycle_count} cycle(s) derived · "
        f"{cycle_signal.pairs_with_seven_day_variability} pair(s) >=7d variable · "
        f"longest gap {cycle_signal.longest_inter_bleed_gap_days or 0}d · "
        f"{'suppressors: ' + ', '.join(suppressors) if suppressors else 'no major suppressors'}"
    )

    return PerimenopauseEvaluationResult(
        analyzer_code=PERIMENOPAUSE_ANALYZER_CODE,
        analyzer_version=PERIMENOPAUSE_ANALYZER_VERSION,
        subject_id=subject_id,
        generated_at=generated_at,
        evaluation_window_start=window_start,
        evaluation_window_end=window_end,
        status=status,
        confidence=confidence,
        straw_stage=stage,
        fmp_candidate_date=fmp_candidate,
        months_since_last_bleed=months_since_last_bleed,
        cycle_signal=cycle_signal,
        symptom_signal=symptom_signal,
        suppressors=suppressors,
        inapplicability_flags=inapplicability,
        differential_reminders=differential_reminders,
        summary=summary,
        evidence_summary=evidence_summary,
        recommended_actions=recommended_actions,
        evidence=[_STRAW_EVIDENCE, _ANALYZER_EVIDENCE],
    )


def _cycle_signal(events: list[ObservationEvent], window_end: date) -> PerimenopauseCycleSignal:
    onsets = _bleeding_onsets(events)
    cycle_lengths: list[int] = []
    for previous, current in zip(onsets, onsets[1:]):
        cycle_lengths.append((current - previous).days)

    pair_diffs: list[int] = []
    for previous_length, current_length in zip(cycle_lengths, cycle_lengths[1:]):
        pair_diffs.append(abs(current_length - previous_length))

    pairs_over_seven = sum(1 for diff in pair_diffs if diff >= 7)
    persistent_seven = False
    if pairs_over_seven >= 1:
        # STRAW+10: recurrence within 10 cycles of the first variable-length cycle.
        first_index = next((i for i, diff in enumerate(pair_diffs) if diff >= 7), None)
        if first_index is not None:
            window = pair_diffs[first_index : first_index + 10]
            persistent_seven = sum(1 for diff in window if diff >= 7) >= 2

    longest_gap: int | None = None
    if onsets:
        longest_gap = max(cycle_lengths) if cycle_lengths else (window_end - onsets[-1]).days
        # The gap from the last bleed to today may exceed any inter-cycle gap.
        tail_gap = (window_end - onsets[-1]).days
        if tail_gap > (longest_gap or 0):
            longest_gap = tail_gap

    last_bleed = onsets[-1] if onsets else None
    amenorrhea_60 = (longest_gap is not None and longest_gap >= 60)
    amenorrhea_365 = (longest_gap is not None and longest_gap >= 365)

    pattern_change = _self_reported_pattern_change(events)

    rationale_parts: list[str] = []
    if cycle_lengths:
        rationale_parts.append(
            f"{len(cycle_lengths)} cycle length(s) derived (range {min(cycle_lengths)}-{max(cycle_lengths)}d)."
        )
    else:
        rationale_parts.append("No derivable cycle lengths within the evaluation window.")
    if persistent_seven:
        rationale_parts.append(
            "Persistent >=7-day consecutive-cycle variability detected (STRAW+10 stage -2 marker)."
        )
    if amenorrhea_365:
        rationale_parts.append(
            f"Longest inter-bleed gap is {longest_gap} days (>=365), retroactively confirming an FMP candidate."
        )
    elif amenorrhea_60:
        rationale_parts.append(
            f"Longest inter-bleed gap is {longest_gap} days (>=60), consistent with late menopausal transition."
        )
    if pattern_change is True:
        rationale_parts.append("User self-reports a recent change in cycle pattern.")

    return PerimenopauseCycleSignal(
        observed_cycle_count=len(cycle_lengths),
        cycle_lengths=cycle_lengths,
        consecutive_pair_differences=pair_diffs,
        max_consecutive_pair_difference=max(pair_diffs) if pair_diffs else None,
        pairs_with_seven_day_variability=pairs_over_seven,
        persistent_seven_day_variability=persistent_seven,
        longest_inter_bleed_gap_days=longest_gap,
        amenorrhea_60_plus_days_observed=amenorrhea_60,
        amenorrhea_365_plus_days_observed=amenorrhea_365,
        last_bleed_date=last_bleed,
        self_reported_pattern_change=pattern_change,
        rationale=" ".join(rationale_parts),
    )


def _symptom_signal(events: list[ObservationEvent]) -> PerimenopauseSymptomSignal:
    severity_counts = {tracker: {value: 0 for value in _SEVERITY_ORDER} for tracker in _SYMPTOM_TRACKERS}
    max_severity: dict[str, str | None] = {tracker: None for tracker in _SYMPTOM_TRACKERS}
    sleep_disturbance = False
    mood_change = False
    for event in events:
        if event.tracker_code in _SYMPTOM_TRACKERS and isinstance(event.value, str):
            value = event.value.lower()
            if value in _SEVERITY_RANK:
                severity_counts[event.tracker_code][value] += 1
                current = max_severity[event.tracker_code]
                if current is None or _SEVERITY_RANK[value] > _SEVERITY_RANK[current]:
                    max_severity[event.tracker_code] = value
        elif event.tracker_code == "sleep_hours":
            try:
                hours = float(event.value)
            except (TypeError, ValueError):
                continue
            if hours < 6:
                sleep_disturbance = True
        elif event.tracker_code == "mood":
            if event.value in {"low", "anxious", "irritable"}:
                mood_change = True

    def _persistent(tracker: str) -> bool:
        counts = severity_counts[tracker]
        return counts["severe"] >= 1 or counts["moderate"] >= 2

    hot_persistent = _persistent("hot_flashes")
    night_persistent = _persistent("night_sweats")
    vaginal_persistent = _persistent("vaginal_dryness")

    qualifying: list[str] = []
    if hot_persistent:
        qualifying.append("hot_flashes_persistent")
    if night_persistent:
        qualifying.append("night_sweats_persistent")
    if vaginal_persistent:
        qualifying.append("vaginal_dryness_persistent")
    if sleep_disturbance:
        qualifying.append("sleep_disturbance")
    if mood_change:
        qualifying.append("mood_change")

    vasomotor_present = hot_persistent or night_persistent
    urogenital_present = vaginal_persistent
    rationale = "Symptom signals: " + (", ".join(qualifying) if qualifying else "none persistent in window")

    return PerimenopauseSymptomSignal(
        hot_flashes_max=max_severity["hot_flashes"],
        night_sweats_max=max_severity["night_sweats"],
        vaginal_dryness_max=max_severity["vaginal_dryness"],
        hot_flashes_persistent=hot_persistent,
        night_sweats_persistent=night_persistent,
        vaginal_dryness_persistent=vaginal_persistent,
        vasomotor_present=vasomotor_present,
        urogenital_atrophy_present=urogenital_present,
        sleep_disturbance_present=sleep_disturbance,
        mood_change_present=mood_change,
        qualifying_features=qualifying,
        rationale=rationale,
    )


def _fmp_candidate(
    *,
    cycle_signal: PerimenopauseCycleSignal,
    known_fmp_date: date | None,
    window_end: date,
) -> tuple[date | None, float | None]:
    if known_fmp_date is not None:
        months = (window_end - known_fmp_date).days / 30.4375
        return known_fmp_date, round(months, 2)
    if cycle_signal.amenorrhea_365_plus_days_observed and cycle_signal.last_bleed_date is not None:
        months = (window_end - cycle_signal.last_bleed_date).days / 30.4375
        return cycle_signal.last_bleed_date, round(months, 2)
    if cycle_signal.last_bleed_date is not None:
        months = (window_end - cycle_signal.last_bleed_date).days / 30.4375
        return None, round(months, 2)
    return None, None


def _stage_from_signals(
    *,
    cycle_signal: PerimenopauseCycleSignal,
    months_since_last_bleed: float | None,
    fmp_confirmed: bool,
) -> str:
    # Post-FMP staging: either >=12 months of amenorrhea from observed cycles,
    # or a user-provided known_fmp_date that gives months_since >= 12.
    if fmp_confirmed and months_since_last_bleed is not None and months_since_last_bleed >= 12:
        if months_since_last_bleed >= 96:
            return "plus_2"
        if months_since_last_bleed >= 36:
            return "plus_1c"
        if months_since_last_bleed >= 24:
            return "plus_1b"
        return "plus_1a"
    if cycle_signal.amenorrhea_60_plus_days_observed:
        return "minus_1"
    if cycle_signal.persistent_seven_day_variability:
        return "minus_2"
    if cycle_signal.self_reported_pattern_change is True:
        return "minus_3a"
    if cycle_signal.observed_cycle_count >= 2:
        # Cycles present, no variability/pattern-change flags.
        return "minus_3b"
    return "indeterminate"


def _status_from_stage(stage: str, *, cycle_signal: PerimenopauseCycleSignal) -> str:
    if stage in {"minus_3b", "minus_3a"}:
        return "reproductive"
    if stage == "minus_2":
        return "early_transition"
    if stage == "minus_1":
        return "late_transition"
    if stage in {"plus_1a", "plus_1b", "plus_1c", "plus_2"}:
        return "postmenopause"
    return "indeterminate"


def _confidence(
    *,
    stage: str,
    cycle_signal: PerimenopauseCycleSignal,
    symptom_signal: PerimenopauseSymptomSignal,
    fmp_confirmed: bool = False,
) -> str:
    if stage == "indeterminate":
        return "none" if cycle_signal.observed_cycle_count == 0 else "low"
    if cycle_signal.amenorrhea_365_plus_days_observed:
        return "high"
    if fmp_confirmed and stage.startswith("plus"):
        # Confidence is rooted in user-confirmed FMP rather than observed amenorrhea.
        return "moderate"
    if stage == "minus_2":
        if cycle_signal.pairs_with_seven_day_variability >= 3 and cycle_signal.observed_cycle_count >= 6:
            return "high"
        return "moderate"
    if stage == "minus_1":
        return "high" if cycle_signal.observed_cycle_count >= 4 else "moderate"
    if cycle_signal.observed_cycle_count >= 6:
        return "high" if not stage.startswith("minus_3a") else "moderate"
    if cycle_signal.observed_cycle_count >= 3:
        return "moderate"
    return "low"


def _summary(
    *,
    status: str,
    stage: str,
    cycle_signal: PerimenopauseCycleSignal,
    symptom_signal: PerimenopauseSymptomSignal,
    months_since_last_bleed: float | None,
) -> str:
    if status == "inapplicable":
        return (
            "STRAW+10 bleeding-based staging is inapplicable after hysterectomy or endometrial ablation. "
            "Symptom and endocrine context should be discussed with a clinician."
        )
    if status == "suppressed":
        return (
            "Cycle-based staging is suppressed because hormonal contraception, pregnancy, postpartum, or "
            "lactation alters bleeding patterns and confounds STRAW+10 cycle criteria."
        )
    if stage == "indeterminate":
        return "Not enough bleeding history in the evaluation window to estimate a STRAW+10 stage."
    stage_descriptions = {
        "minus_3b": "Late reproductive (regular cycles, no transition markers detected yet).",
        "minus_3a": "Late reproductive with subtle cycle changes self-reported (STRAW+10 stage -3a).",
        "minus_2": "Early menopausal transition: persistent >=7-day cycle-length variability detected.",
        "minus_1": "Late menopausal transition: amenorrhea of 60+ days observed in the window.",
        "plus_1a": "Early postmenopause year 1 (12-24 months since the last menstrual period).",
        "plus_1b": "Early postmenopause year 2 (24-36 months since the last menstrual period).",
        "plus_1c": "Early postmenopause stabilization (3-8 years since the last menstrual period).",
        "plus_2": "Late postmenopause (more than ~8 years since the last menstrual period).",
    }
    base = stage_descriptions.get(stage, "STRAW+10 stage estimate.")
    if months_since_last_bleed is not None and stage.startswith("plus"):
        base += f" Approximately {months_since_last_bleed:.1f} months since the last bleed."
    if symptom_signal.vasomotor_present and stage in {"minus_2", "minus_1", "plus_1a", "plus_1b"}:
        base += " Vasomotor symptoms are consistent with this stage."
    return base


def _recommended_actions(
    *,
    status: str,
    stage: str,
    cycle_signal: PerimenopauseCycleSignal,
    symptom_signal: PerimenopauseSymptomSignal,
    chronological_age: float | None,
    suppressors: list[str],
) -> list[str]:
    actions: list[str] = []
    if status == "inapplicable":
        actions.append(
            "STRAW+10 menstrual criteria do not apply after hysterectomy or endometrial ablation; clinician may use "
            "symptoms and endocrine markers (FSH, estradiol) instead."
        )
        return actions
    if status == "suppressed":
        actions.append(
            "Hormonal contraception, pregnancy, postpartum, or lactation confounds STRAW+10 cycle criteria; "
            "clinician staging may require a treatment pause and serial FSH/AMH measurements."
        )
        return actions
    if stage == "indeterminate":
        actions.append("Continue logging period_bleeding consistently; STRAW+10 staging needs at least several cycles of history.")
        return actions
    if stage in {"minus_3b", "minus_3a"}:
        actions.append(
            "Cycle pattern is consistent with the late reproductive stage; document any new symptoms and consider "
            "preventive care (cardiovascular and bone health) with a clinician."
        )
    elif stage == "minus_2":
        actions.append(
            "Early menopausal transition is suggested by >=7-day cycle variability; discuss symptom management "
            "options and bone/cardiovascular risk with a clinician."
        )
    elif stage == "minus_1":
        actions.append(
            "Late menopausal transition is suggested by >=60-day amenorrhea; vasomotor symptom management and "
            "post-FMP planning (cardiovascular, bone, urogenital) are reasonable clinician topics."
        )
    elif stage.startswith("plus_1"):
        actions.append(
            "Early postmenopause: discuss bone density, cardiovascular risk reduction, and management of vasomotor or "
            "urogenital symptoms with a clinician."
        )
    elif stage == "plus_2":
        actions.append(
            "Late postmenopause: continue routine bone, cardiovascular, and urogenital health follow-up; "
            "discuss any new bleeding with a clinician promptly (post-menopausal bleeding warrants evaluation)."
        )
    if symptom_signal.urogenital_atrophy_present:
        actions.append("Persistent vaginal dryness is consistent with urogenital atrophy; effective topical and systemic treatments exist - discuss with a clinician.")
    if symptom_signal.vasomotor_present and stage in {"minus_2", "minus_1", "plus_1a", "plus_1b"}:
        actions.append("Vasomotor symptom severity can be reduced by lifestyle, non-hormonal, and hormonal options; discuss preferences with a clinician.")
    if chronological_age is not None and chronological_age < 40 and stage in {"minus_2", "minus_1", "plus_1a", "plus_1b", "plus_1c", "plus_2"}:
        actions.append(
            "Transition or postmenopausal stage under age 40 should be evaluated for primary ovarian insufficiency "
            "rather than typical menopause."
        )
    actions.append(
        "Differential reminders: thyroid dysfunction, hyperprolactinemia, hypothalamic amenorrhea, Asherman syndrome, "
        "and endometrial pathology should be ruled out for unexplained changes in bleeding."
    )
    return actions


def _collect_suppressors(events: list[ObservationEvent], window_end: date) -> list[str]:
    suppressors: set[str] = set()
    contraception_use: str | None = None
    contraception_use_at: datetime | None = None
    contraception_start: date | None = None
    contraception_stop: date | None = None
    for event in events:
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


def _self_reported_pattern_change(events: list[ObservationEvent]) -> bool | None:
    reports = [
        event.value
        for event in events
        if event.tracker_code == "cycle_pattern_change" and isinstance(event.value, str)
    ]
    if not reports:
        return None
    latest = reports[-1]
    if latest == "yes":
        return True
    if latest == "no":
        return False
    return None


def _observed_day(event: ObservationEvent) -> date:
    return event.observed_on or event.observed_at.date()
