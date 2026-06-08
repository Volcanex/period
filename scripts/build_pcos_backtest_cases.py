#!/usr/bin/env python3
"""Build the deterministic PCOS analyzer backtest fixture.

This script is the source of truth for tests/data/pcos_backtest_cases.json.
Cases are designed to exercise each branch of the analyzer against the 2023
International Evidence-based Guideline rules without inventing biological
ground truth that the analyzer would otherwise be claiming to detect.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "tests" / "data" / "pcos_backtest_cases.json"


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


def _bleed_cycle(builder: EventBuilder, onset: date, length_days: int = 4, value: str = "medium") -> list[dict]:
    return [builder.event(onset + timedelta(days=offset), "period_bleeding", value) for offset in range(length_days)]


def _bleed_series(builder: EventBuilder, start: date, gaps: list[int], *, length_days: int = 4) -> list[dict]:
    events: list[dict] = []
    onset = start
    events.extend(_bleed_cycle(builder, onset, length_days=length_days))
    for gap in gaps:
        onset = onset + timedelta(days=gap)
        events.extend(_bleed_cycle(builder, onset, length_days=length_days))
    return events


def _persistent(builder: EventBuilder, anchor: date, tracker_code: str, severities: list[tuple[int, str]]) -> list[dict]:
    return [builder.event(anchor + timedelta(days=offset), tracker_code, value) for offset, value in severities]


def case_adult_features_present() -> dict:
    b = EventBuilder("pcos-case-1")
    obs = _bleed_series(b, date(2026, 1, 4), [42, 47, 60])
    obs.extend(_persistent(b, date(2026, 3, 10), "acne_severity", [(0, "severe"), (5, "moderate"), (12, "severe")]))
    obs.extend(_persistent(b, date(2026, 4, 1), "hair_growth", [(0, "moderate"), (10, "moderate"), (20, "moderate")]))
    obs.append(b.event(date(2026, 5, 1), "weight", 78.2, unit="kg"))
    return {
        "case_id": "adult-features-present",
        "subject_id": "pcos-case-1",
        "expected_status": "features_present",
        "years_since_menarche": 12,
        "observations": obs,
    }


def case_adult_features_absent() -> dict:
    b = EventBuilder("pcos-case-2")
    obs = _bleed_series(b, date(2026, 1, 5), [28, 28, 29, 30, 28])
    obs.append(b.event(date(2026, 4, 1), "weight", 60.0, unit="kg"))
    return {
        "case_id": "adult-features-absent",
        "subject_id": "pcos-case-2",
        "expected_status": "features_absent",
        "years_since_menarche": 14,
        "observations": obs,
    }


def case_adult_irregularity_only() -> dict:
    b = EventBuilder("pcos-case-3")
    obs = _bleed_series(b, date(2026, 1, 6), [44, 51])
    obs.append(b.event(date(2026, 4, 10), "acne_severity", "mild"))
    return {
        "case_id": "adult-irregularity-only",
        "subject_id": "pcos-case-3",
        "expected_status": "features_partial",
        "years_since_menarche": 8,
        "observations": obs,
    }


def case_adult_hyperandrogenism_only() -> dict:
    b = EventBuilder("pcos-case-4")
    obs = _bleed_series(b, date(2026, 1, 7), [29, 30, 29, 30])
    obs.extend(_persistent(b, date(2026, 2, 5), "hair_growth", [(0, "severe"), (15, "moderate"), (30, "moderate")]))
    obs.extend(_persistent(b, date(2026, 2, 10), "acne_severity", [(0, "moderate"), (12, "moderate")]))
    return {
        "case_id": "adult-hyperandrogenism-only",
        "subject_id": "pcos-case-4",
        "expected_status": "features_partial",
        "years_since_menarche": 10,
        "observations": obs,
    }


def case_adolescent_pubertal_feature_noise() -> dict:
    b = EventBuilder("pcos-case-5")
    obs = _bleed_series(b, date(2026, 1, 10), [55, 48])
    obs.extend(_persistent(b, date(2026, 3, 1), "acne_severity", [(0, "severe"), (10, "severe")]))
    return {
        "case_id": "adolescent-pubertal-feature-noise",
        "subject_id": "pcos-case-5",
        "expected_status": "features_partial",
        "years_since_menarche": 0.6,
        "observations": obs,
    }


def case_adolescent_early_both() -> dict:
    b = EventBuilder("pcos-case-6")
    obs = _bleed_series(b, date(2026, 1, 8), [58, 49])
    obs.extend(_persistent(b, date(2026, 3, 5), "acne_severity", [(0, "severe"), (15, "moderate")]))
    obs.extend(_persistent(b, date(2026, 4, 1), "hair_growth", [(0, "moderate"), (10, "moderate")]))
    return {
        "case_id": "adolescent-early-both",
        "subject_id": "pcos-case-6",
        "expected_status": "features_present",
        "years_since_menarche": 2.0,
        "observations": obs,
    }


def case_suppressed_cocp() -> dict:
    b = EventBuilder("pcos-case-7")
    obs = _bleed_series(b, date(2026, 1, 5), [40, 45])
    obs.extend(_persistent(b, date(2026, 2, 1), "acne_severity", [(0, "severe"), (10, "moderate")]))
    obs.append(b.event(date(2026, 1, 1), "contraception_use", "pill"))
    obs.append(b.event(date(2026, 1, 1), "contraception_start", "2026-01-01"))
    return {
        "case_id": "suppressed-cocp",
        "subject_id": "pcos-case-7",
        "expected_status": "suppressed",
        "years_since_menarche": 11,
        "observations": obs,
    }


def case_suppressed_pregnancy() -> dict:
    b = EventBuilder("pcos-case-8")
    obs = _bleed_series(b, date(2026, 1, 7), [60])
    obs.append(b.event(date(2026, 4, 1), "pregnancy_test", "positive"))
    obs.extend(_persistent(b, date(2026, 2, 10), "acne_severity", [(0, "moderate"), (12, "moderate")]))
    return {
        "case_id": "suppressed-pregnancy",
        "subject_id": "pcos-case-8",
        "expected_status": "suppressed",
        "years_since_menarche": 9,
        "observations": obs,
    }


def case_insufficient_data() -> dict:
    b = EventBuilder("pcos-case-9")
    obs = [b.event(date(2026, 4, 28), "period_bleeding", "medium")]
    return {
        "case_id": "insufficient-data",
        "subject_id": "pcos-case-9",
        "expected_status": "insufficient_data",
        "years_since_menarche": 10,
        "observations": obs,
    }


def case_fallback_self_report() -> dict:
    b = EventBuilder("pcos-case-10")
    obs = [
        b.event(date(2026, 5, 1), "cycle_regularity", "infrequent"),
        b.event(date(2026, 3, 1), "hair_growth", "severe"),
        b.event(date(2026, 3, 20), "hair_growth", "moderate"),
        b.event(date(2026, 4, 10), "hair_growth", "moderate"),
        b.event(date(2026, 4, 30), "acanthosis_nigricans", True),
        b.event(date(2026, 5, 1), "weight", 90.5, unit="kg"),
    ]
    return {
        "case_id": "fallback-self-report-irregular",
        "subject_id": "pcos-case-10",
        "expected_status": "features_present",
        "years_since_menarche": 12,
        "observations": obs,
    }


def main() -> int:
    cases = [
        case_adult_features_present(),
        case_adult_features_absent(),
        case_adult_irregularity_only(),
        case_adult_hyperandrogenism_only(),
        case_adolescent_pubertal_feature_noise(),
        case_adolescent_early_both(),
        case_suppressed_cocp(),
        case_suppressed_pregnancy(),
        case_insufficient_data(),
        case_fallback_self_report(),
    ]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(cases, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(cases)} cases to {OUTPUT.relative_to(PROJECT_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
