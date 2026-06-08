#!/usr/bin/env python3
"""Build the deterministic perimenopause STRAW+10 analyzer backtest fixture.

This script is the source of truth for
tests/data/perimenopause_backtest_cases.json. Cases are designed to exercise
each STRAW+10 stage and the inapplicability/suppressor branches against the
Harlow et al. 2012 executive summary. Fixed anchor: 2027-01-01.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "tests" / "data" / "perimenopause_backtest_cases.json"

EVALUATION_ANCHOR = date(2027, 1, 1)


@dataclass
class EventBuilder:
    subject_id: str
    next_index: int = 1

    def event(self, day: date, tracker_code: str, value, *, unit: str | None = None) -> dict:
        record = {
            "id": f"{self.subject_id}-{self.next_index:03d}",
            "subject_id": self.subject_id,
            "tracker_code": tracker_code,
            "observed_at": f"{day.isoformat()}T12:00:00Z",
            "observed_on": day.isoformat(),
            "source": "user_entered",
            "value": value,
        }
        if unit is not None:
            record["unit"] = unit
        self.next_index += 1
        return record


def _bleed_cycle(builder: EventBuilder, onset: date, length_days: int = 4) -> list[dict]:
    return [builder.event(onset + timedelta(days=offset), "period_bleeding", "medium") for offset in range(length_days)]


def _bleed_from_onsets(builder: EventBuilder, onsets: list[date], length_days: int = 4) -> list[dict]:
    events: list[dict] = []
    for onset in onsets:
        events.extend(_bleed_cycle(builder, onset, length_days=length_days))
    return events


def _symptom_run(builder: EventBuilder, anchor: date, tracker_code: str, severities: list[tuple[int, str]]) -> list[dict]:
    return [builder.event(anchor + timedelta(days=offset), tracker_code, value) for offset, value in severities]


def case_reproductive_minus_3b() -> dict:
    """Regular ~28d cycles, no symptoms, age 32."""
    b = EventBuilder("perimeno-case-1")
    onsets = [EVALUATION_ANCHOR - timedelta(days=28 * (12 - i)) for i in range(12)]
    obs = _bleed_from_onsets(b, onsets)
    return {
        "case_id": "reproductive-minus-3b",
        "subject_id": "perimeno-case-1",
        "expected_status": "reproductive",
        "expected_stage": "minus_3b",
        "chronological_age": 32,
        "observations": obs,
    }


def case_late_reproductive_minus_3a() -> dict:
    """Cycles becoming subtly shorter; user reports pattern change."""
    b = EventBuilder("perimeno-case-2")
    lengths = [29, 28, 27, 26, 26, 25, 24, 24, 25, 24]
    onsets = []
    cur = EVALUATION_ANCHOR - timedelta(days=sum(lengths))
    for length in lengths:
        onsets.append(cur)
        cur = cur + timedelta(days=length)
    obs = _bleed_from_onsets(b, onsets)
    obs.append(b.event(EVALUATION_ANCHOR - timedelta(days=30), "cycle_pattern_change", "yes"))
    return {
        "case_id": "late-reproductive-minus-3a",
        "subject_id": "perimeno-case-2",
        "expected_status": "reproductive",
        "expected_stage": "minus_3a",
        "chronological_age": 42,
        "observations": obs,
    }


def case_early_transition_minus_2() -> dict:
    """Persistent >=7 day differences in consecutive cycles."""
    b = EventBuilder("perimeno-case-3")
    lengths = [28, 29, 38, 30, 41, 33, 44, 32, 42, 35]
    onsets = []
    cur = EVALUATION_ANCHOR - timedelta(days=sum(lengths))
    for length in lengths:
        onsets.append(cur)
        cur = cur + timedelta(days=length)
    obs = _bleed_from_onsets(b, onsets)
    obs.extend(_symptom_run(b, EVALUATION_ANCHOR - timedelta(days=60), "hot_flashes", [(0, "moderate"), (12, "mild")]))
    return {
        "case_id": "early-transition-minus-2",
        "subject_id": "perimeno-case-3",
        "expected_status": "early_transition",
        "expected_stage": "minus_2",
        "chronological_age": 46,
        "observations": obs,
    }


def case_late_transition_minus_1() -> dict:
    """Amenorrhea of 90 days observed within window."""
    b = EventBuilder("perimeno-case-4")
    onsets = [
        EVALUATION_ANCHOR - timedelta(days=400),
        EVALUATION_ANCHOR - timedelta(days=370),
        EVALUATION_ANCHOR - timedelta(days=330),
        EVALUATION_ANCHOR - timedelta(days=280),
        EVALUATION_ANCHOR - timedelta(days=190),  # 90 day gap
        EVALUATION_ANCHOR - timedelta(days=140),
        EVALUATION_ANCHOR - timedelta(days=80),
    ]
    obs = _bleed_from_onsets(b, onsets)
    obs.extend(_symptom_run(b, EVALUATION_ANCHOR - timedelta(days=120), "hot_flashes", [(0, "severe"), (15, "moderate"), (30, "moderate")]))
    obs.extend(_symptom_run(b, EVALUATION_ANCHOR - timedelta(days=100), "night_sweats", [(0, "moderate"), (12, "moderate")]))
    return {
        "case_id": "late-transition-minus-1",
        "subject_id": "perimeno-case-4",
        "expected_status": "late_transition",
        "expected_stage": "minus_1",
        "chronological_age": 49,
        "observations": obs,
    }


def case_postmenopause_plus_1a() -> dict:
    """14 months since last bleed; FMP confirmed retroactively."""
    b = EventBuilder("perimeno-case-5")
    last_bleed = EVALUATION_ANCHOR - timedelta(days=14 * 30)  # 420 days
    onsets = [last_bleed - timedelta(days=120), last_bleed - timedelta(days=60), last_bleed]
    obs = _bleed_from_onsets(b, onsets)
    obs.extend(_symptom_run(b, EVALUATION_ANCHOR - timedelta(days=180), "hot_flashes", [(0, "severe"), (20, "moderate"), (45, "moderate")]))
    obs.extend(_symptom_run(b, EVALUATION_ANCHOR - timedelta(days=60), "vaginal_dryness", [(0, "moderate"), (12, "moderate")]))
    return {
        "case_id": "postmenopause-plus-1a",
        "subject_id": "perimeno-case-5",
        "expected_status": "postmenopause",
        "expected_stage": "plus_1a",
        "chronological_age": 52,
        "observations": obs,
    }


def case_postmenopause_plus_1b_known_fmp() -> dict:
    """User-provided FMP 30 months ago."""
    b = EventBuilder("perimeno-case-6")
    known_fmp = EVALUATION_ANCHOR - timedelta(days=30 * 30)  # 900 days
    obs = [
        b.event(EVALUATION_ANCHOR - timedelta(days=180), "vaginal_dryness", "moderate"),
        b.event(EVALUATION_ANCHOR - timedelta(days=160), "vaginal_dryness", "moderate"),
    ]
    return {
        "case_id": "postmenopause-plus-1b-known-fmp",
        "subject_id": "perimeno-case-6",
        "expected_status": "postmenopause",
        "expected_stage": "plus_1b",
        "chronological_age": 54,
        "known_fmp_date": known_fmp.isoformat(),
        "observations": obs,
    }


def case_postmenopause_plus_1c_known_fmp() -> dict:
    """User-provided FMP 60 months ago (5 years)."""
    b = EventBuilder("perimeno-case-7")
    known_fmp = EVALUATION_ANCHOR - timedelta(days=60 * 30)
    obs = [b.event(EVALUATION_ANCHOR - timedelta(days=10), "vaginal_dryness", "mild")]
    return {
        "case_id": "postmenopause-plus-1c-known-fmp",
        "subject_id": "perimeno-case-7",
        "expected_status": "postmenopause",
        "expected_stage": "plus_1c",
        "chronological_age": 57,
        "known_fmp_date": known_fmp.isoformat(),
        "observations": obs,
    }


def case_postmenopause_plus_2_known_fmp() -> dict:
    """User-provided FMP 100 months ago (>96 months)."""
    b = EventBuilder("perimeno-case-8")
    known_fmp = EVALUATION_ANCHOR - timedelta(days=100 * 30)
    obs = [b.event(EVALUATION_ANCHOR - timedelta(days=30), "vaginal_dryness", "moderate")]
    return {
        "case_id": "postmenopause-plus-2-known-fmp",
        "subject_id": "perimeno-case-8",
        "expected_status": "postmenopause",
        "expected_stage": "plus_2",
        "chronological_age": 61,
        "known_fmp_date": known_fmp.isoformat(),
        "observations": obs,
    }


def case_suppressed_cocp() -> dict:
    """Combined oral contraceptive in window."""
    b = EventBuilder("perimeno-case-9")
    onsets = [EVALUATION_ANCHOR - timedelta(days=28 * (6 - i)) for i in range(6)]
    obs = _bleed_from_onsets(b, onsets)
    obs.append(b.event(EVALUATION_ANCHOR - timedelta(days=200), "contraception_use", "pill"))
    return {
        "case_id": "suppressed-cocp",
        "subject_id": "perimeno-case-9",
        "expected_status": "suppressed",
        "expected_stage": "indeterminate",
        "chronological_age": 47,
        "observations": obs,
    }


def case_inapplicable_post_hysterectomy() -> dict:
    """Post-hysterectomy with vasomotor symptoms only."""
    b = EventBuilder("perimeno-case-10")
    obs = [
        b.event(EVALUATION_ANCHOR - timedelta(days=180), "hot_flashes", "severe"),
        b.event(EVALUATION_ANCHOR - timedelta(days=120), "hot_flashes", "moderate"),
        b.event(EVALUATION_ANCHOR - timedelta(days=60), "vaginal_dryness", "moderate"),
    ]
    return {
        "case_id": "inapplicable-post-hysterectomy",
        "subject_id": "perimeno-case-10",
        "expected_status": "inapplicable",
        "expected_stage": "indeterminate",
        "chronological_age": 51,
        "post_hysterectomy": True,
        "observations": obs,
    }


def case_indeterminate_too_few_cycles() -> dict:
    """One recent bleed onset, no derivable cycles or amenorrhea."""
    b = EventBuilder("perimeno-case-11")
    obs = _bleed_cycle(b, EVALUATION_ANCHOR - timedelta(days=20))
    return {
        "case_id": "indeterminate-too-few-cycles",
        "subject_id": "perimeno-case-11",
        "expected_status": "indeterminate",
        "expected_stage": "indeterminate",
        "chronological_age": 44,
        "observations": obs,
    }


def case_premature_under_40_late_transition() -> dict:
    """Late transition pattern under age 40 -> differential reminder for POI."""
    b = EventBuilder("perimeno-case-12")
    onsets = [
        EVALUATION_ANCHOR - timedelta(days=400),
        EVALUATION_ANCHOR - timedelta(days=360),
        EVALUATION_ANCHOR - timedelta(days=310),
        EVALUATION_ANCHOR - timedelta(days=260),
        EVALUATION_ANCHOR - timedelta(days=160),  # 100 day gap
        EVALUATION_ANCHOR - timedelta(days=90),
    ]
    obs = _bleed_from_onsets(b, onsets)
    return {
        "case_id": "premature-under-40-late-transition",
        "subject_id": "perimeno-case-12",
        "expected_status": "late_transition",
        "expected_stage": "minus_1",
        "chronological_age": 35,
        "observations": obs,
    }


def main() -> int:
    cases = [
        case_reproductive_minus_3b(),
        case_late_reproductive_minus_3a(),
        case_early_transition_minus_2(),
        case_late_transition_minus_1(),
        case_postmenopause_plus_1a(),
        case_postmenopause_plus_1b_known_fmp(),
        case_postmenopause_plus_1c_known_fmp(),
        case_postmenopause_plus_2_known_fmp(),
        case_suppressed_cocp(),
        case_inapplicable_post_hysterectomy(),
        case_indeterminate_too_few_cycles(),
        case_premature_under_40_late_transition(),
    ]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(cases, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(cases)} cases to {OUTPUT.relative_to(PROJECT_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
