#!/usr/bin/env python3
"""Export Flutter-facing OpenAPI and example contract payloads."""

from __future__ import annotations

import json
import sys
from datetime import UTC, date, datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.contracts import (  # noqa: E402
    AnalysisResult,
    Analyzer,
    CalendarAnnotation,
    CycleProjection,
    CycleState,
    LocalDataBundle,
    LocalStoreMetadata,
    LocalStoreSnapshot,
    RecordLifecycle,
    ObservationEvent,
    Prediction,
    Report,
    Subject,
    TrackerPreference,
    TrackerSettings,
)
from core.contracts.versioning import check_contract_compatibility, contract_version
from core.privacy import privacy_manifest  # noqa: E402
from core.bundles import local_store_snapshot_to_bundle
from core.tracking import default_tracker_settings, resolve_tracker_settings, tracker_packs, tracker_registry  # noqa: E402
from server import app  # noqa: E402

SNAPSHOT_DIR = PROJECT_ROOT / "contract_snapshot"
EXAMPLES_DIR = SNAPSHOT_DIR / "examples"


def _dumpable(value):
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if hasattr(value, "dict"):
        return value.dict()
    if isinstance(value, list):
        return [_dumpable(item) for item in value]
    if isinstance(value, dict):
        return {key: _dumpable(item) for key, item in value.items()}
    return value


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(_dumpable(payload), indent=2, sort_keys=True) + "\n", encoding="utf-8")


def examples() -> dict[str, object]:
    now = datetime(2026, 5, 2, 10, 30, tzinfo=UTC)
    subject = Subject(
        id="subject-demo-1",
        birth_year=1994,
        timezone="Asia/Ho_Chi_Minh",
        locale="en-US",
        sex_at_birth="female",
        gender_identity=None,
        menarche_age=12.5,
        consent_flags={"research_export": False, "clinician_export": True},
    )
    observation = ObservationEvent(
        id="obs-demo-cramps-1",
        subject_id=subject.id,
        tracker_code="cramps",
        observed_at=now,
        observed_on=date(2026, 5, 2),
        source="user_entered",
        value="moderate",
    )
    projection = CycleProjection(
        id="cycle-demo-1",
        subject_id=subject.id,
        cycle_index=12,
        state=CycleState.ongoing,
        started_on=date(2026, 4, 29),
        ended_on=None,
        derived_from_event_ids=[observation.id],
        generated_at=now,
        algorithm_version="period-core-local-v1",
        confidence=0.72,
    )
    prediction = Prediction(
        id="prediction-demo-1",
        subject_id=subject.id,
        generated_at=now,
        algorithm_version="period-core-local-v1",
        next_period={"date": "2026-05-28", "p10": "2026-05-25", "p90": "2026-06-01"},
        ovulation={"date": "2026-05-14", "confidence": 0.48},
        fertile_window={"start_date": "2026-05-10", "end_date": "2026-05-15"},
        luteal_length={"days": 13.5, "source": "client_estimate"},
        confidence=0.68,
    )
    analyzer = Analyzer(
        code="cycle_length_backtest_summary",
        display_name="Cycle length backtest summary",
        description="Metadata-only analyzer declaration for reproducible model evaluation outputs.",
        input_contracts=["ObservationEvent", "CycleProjection"],
        output_contract="AnalysisResult",
        version="2026.05.02",
    )
    analysis_result = AnalysisResult(
        id="analysis-demo-1",
        analyzer_code=analyzer.code,
        analyzer_version=analyzer.version,
        subject_id=subject.id,
        generated_at=now,
        result_type="model_backtest_summary",
        payload={"mae_days": 2.32, "p80_coverage": 0.79, "folds": 6321},
    )
    report = Report(
        id="report-demo-1",
        subject_id=subject.id,
        generated_at=now,
        report_type="clinician_summary",
        title="Clinician summary export",
        summary="User-controlled summary of selected observations and derived projections.",
        included_event_ids=[observation.id],
        included_projection_ids=[projection.id],
        included_prediction_ids=[prediction.id],
        export_metadata={"format": "json", "generated_on_device": True},
    )
    annotation = CalendarAnnotation(
        id="cal-demo-cramps-1",
        subject_id=subject.id,
        source_type="observation",
        source_id=observation.id,
        date=date(2026, 5, 2),
        layer="symptom",
        label="Cramps",
        tracker_code="cramps",
        value="moderate",
        priority=50,
    )
    tracker_settings = default_tracker_settings(subject.id)
    tracker_settings.enabled_pack_codes.append("pcos_support")
    tracker_settings.tracker_preferences.append(
        TrackerPreference(tracker_code="acne_severity", enabled=True, pinned=True, display_order=0)
    )
    active_catalog = resolve_tracker_settings(tracker_settings).active_catalog
    local_store_snapshot = LocalStoreSnapshot(
        metadata=LocalStoreMetadata(
            schema_version="2026.05.02",
            app_version="period-flutter-dev",
            device_timezone=subject.timezone,
            created_at=now,
            updated_at=now,
            last_exported_at=now,
            notes=["Demo local store snapshot for Flutter model parity."],
        ),
        subject=subject,
        tracker_settings=tracker_settings,
        observations=[observation],
        cycle_projections=[projection],
        predictions=[prediction],
        reports=[report],
        record_lifecycle={
            subject.id: RecordLifecycle(created_at=now, updated_at=now),
            f"tracker_settings:{subject.id}": RecordLifecycle(created_at=now, updated_at=now),
            observation.id: RecordLifecycle(created_at=now, updated_at=now),
            projection.id: RecordLifecycle(created_at=now, updated_at=now),
            prediction.id: RecordLifecycle(created_at=now, updated_at=now),
            report.id: RecordLifecycle(created_at=now, updated_at=now),
        },
    )
    bundle = local_store_snapshot_to_bundle(local_store_snapshot)
    packs = {pack.code: pack for pack in tracker_packs()}
    registry = tracker_registry()
    return {
        "subject.demo.json": subject,
        "tracker-definition.period-bleeding.json": registry["period_bleeding"],
        "tracker-pack.pcos-support.json": packs["pcos_support"],
        "tracker-pack.endometriosis-support.json": packs["endometriosis_support"],
        "tracker-settings.demo.json": tracker_settings,
        "active-tracker-catalog.demo.json": active_catalog,
        "observation.cramps.valid.json": observation,
        "cycle-projection.ongoing.json": projection,
        "prediction.client-derived.json": prediction,
        "analyzer.metadata.json": analyzer,
        "analysis-result.backtest-summary.json": analysis_result,
        "report.clinician-summary.json": report,
        "calendar-annotation.cramps.json": annotation,
        "local-store-snapshot.demo.json": local_store_snapshot,
        "local-data-bundle.demo.json": bundle,
        "privacy-manifest.v1.json": privacy_manifest(),
    }


def main() -> int:
    write_json(SNAPSHOT_DIR / "openapi.v1.json", app.openapi())
    write_json(SNAPSHOT_DIR / "contract-version.v1.json", contract_version())
    write_json(SNAPSHOT_DIR / "contract-changelog.v1.json", contract_version().changelog)
    write_json(EXAMPLES_DIR / "contract-compatibility.accepted.json", check_contract_compatibility("2026.05.02"))
    write_json(EXAMPLES_DIR / "contract-compatibility.unsupported.json", check_contract_compatibility("2026.01.01"))
    for name, payload in examples().items():
        write_json(EXAMPLES_DIR / name, payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
