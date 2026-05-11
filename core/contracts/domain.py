"""Pydantic models for Period's backend/mobile contract boundary."""

from __future__ import annotations

from datetime import date, datetime
from enum import StrEnum
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ContractModel(BaseModel):
    """Base model that rejects accidental contract drift."""

    model_config = ConfigDict(extra="forbid")


class EvidenceReference(ContractModel):
    source: str = Field(..., description="Human-readable source or citation label.")
    assumption: str | None = Field(None, description="Assumption this evidence depends on.")
    confidence: float | None = Field(None, ge=0, le=1)
    version: str | None = None
    review_status: Literal["draft", "reviewed", "deprecated"] = "draft"


class ContractChangelogEntry(ContractModel):
    version: str
    released_on: date
    change_type: Literal["initial", "additive", "breaking"]
    summary: str
    migration_note: str | None = None


class ContractVersion(ContractModel):
    current_version: str
    supported_versions: list[str]
    minimum_supported_version: str
    compatibility_policy: str
    changelog: list[ContractChangelogEntry] = Field(default_factory=list)


class ContractCompatibilityRequest(ContractModel):
    schema_version: str


class ContractCompatibilityResult(ContractModel):
    schema_version: str
    status: Literal["accepted", "accepted_with_warnings", "unsupported_version"]
    current_version: str
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    migration_required: bool = False


class Subject(ContractModel):
    id: str
    birth_year: int | None = Field(None, ge=1900, le=2100)
    timezone: str
    locale: str
    sex_at_birth: Literal["female", "male", "intersex", "unknown", "prefer_not_to_say"] | None = None
    gender_identity: str | None = None
    menarche_age: float | None = Field(None, ge=0, le=30)
    consent_flags: dict[str, bool] = Field(default_factory=dict)


class TrackerDefinition(ContractModel):
    code: str
    display_name: str
    value_type: Literal["boolean", "integer", "decimal", "string", "enum", "date", "datetime", "duration"]
    temporal_grain: Literal["instant", "day", "date_range", "cycle"] = "instant"
    calendar_layer: Literal["none", "bleeding", "symptom", "temperature", "context", "prediction", "cycle"] = "symptom"
    calendar_priority: int = Field(default=50, ge=0, le=100)
    unit: str | None = None
    allowed_values: list[str] | None = None
    validation_schema: dict[str, Any] = Field(default_factory=dict)
    fhir_mapping: dict[str, Any] | None = None
    healthkit_mapping: dict[str, Any] | None = None
    health_connect_mapping: dict[str, Any] | None = None
    version: str
    evidence: list[EvidenceReference] = Field(default_factory=list)


class TrackerPack(ContractModel):
    code: str
    display_name: str
    description: str
    tracker_codes: list[str]
    enabled_by_default: bool = False
    clinical_note: str | None = None
    evidence: list[EvidenceReference] = Field(default_factory=list)




class TrackerPreference(ContractModel):
    tracker_code: str
    enabled: bool = True
    pinned: bool = False
    display_order: int | None = Field(None, ge=0)
    custom_display_name: str | None = Field(None, max_length=80)


class TrackerSettings(ContractModel):
    subject_id: str
    enabled_pack_codes: list[str] = Field(default_factory=list)
    disabled_tracker_codes: list[str] = Field(default_factory=list)
    tracker_preferences: list[TrackerPreference] = Field(default_factory=list)
    updated_at: datetime
    schema_version: str


class ActiveTrackerCatalog(ContractModel):
    subject_id: str
    settings_schema_version: str
    enabled_pack_codes: list[str]
    tracker_definitions: list[TrackerDefinition]
    tracker_preferences: list[TrackerPreference] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)


class TrackerSettingsResolutionRequest(ContractModel):
    settings: TrackerSettings


class TrackerSettingsValidationResult(ContractModel):
    ok: bool
    errors: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    active_catalog: ActiveTrackerCatalog | None = None

class ObservationEvent(ContractModel):
    id: str
    subject_id: str
    tracker_code: str
    observed_at: datetime
    observed_on: date | None = None
    ended_at: datetime | None = None
    source: Literal["user_entered", "imported"]
    value: Any
    unit: str | None = None
    raw_payload: dict[str, Any] | None = None
    note: str | None = None


class ObservationValidationRequest(ContractModel):
    event: ObservationEvent


class ObservationValidationResult(ContractModel):
    ok: bool
    tracker_code: str
    errors: list[str] = Field(default_factory=list)


class CalendarAnnotation(ContractModel):
    id: str
    subject_id: str
    source_type: Literal["observation", "cycle_projection", "prediction"]
    source_id: str
    date: date
    end_date: date | None = None
    layer: Literal["bleeding", "symptom", "temperature", "context", "prediction", "cycle"]
    label: str
    tracker_code: str | None = None
    value: Any | None = None
    priority: int = Field(default=50, ge=0, le=100)


class CycleState(StrEnum):
    unknown = "unknown"
    ongoing = "ongoing"
    completed = "completed"
    skipped_tracking_suspected = "skipped_tracking_suspected"
    anovulatory_suspected = "anovulatory_suspected"
    amenorrhea = "amenorrhea"
    pregnancy = "pregnancy"
    postpartum = "postpartum"
    lactating = "lactating"
    hormonal_contraception = "hormonal_contraception"
    perimenopausal_irregular = "perimenopausal_irregular"


class CalendarRange(ContractModel):
    start_date: date
    end_date: date

    @model_validator(mode="after")
    def check_date_order(self) -> "CalendarRange":
        if self.end_date < self.start_date:
            raise ValueError("end_date must be on or after start_date")
        return self


class CalendarDay(ContractModel):
    date: date
    annotations: list[CalendarAnnotation] = Field(default_factory=list)
    cycle_state: CycleState | None = None


class CalendarFeed(ContractModel):
    subject_id: str
    range: CalendarRange
    days: list[CalendarDay]


class CycleProjection(ContractModel):
    id: str
    subject_id: str
    cycle_index: int | None = None
    state: CycleState
    started_on: date | None = None
    ended_on: date | None = None
    derived_from_event_ids: list[str] = Field(default_factory=list)
    generated_at: datetime
    algorithm_version: str
    confidence: float | None = Field(None, ge=0, le=1)


class Prediction(ContractModel):
    id: str
    subject_id: str
    generated_at: datetime
    algorithm_version: str
    next_period: dict[str, Any] | None = None
    ovulation: dict[str, Any] | None = None
    fertile_window: dict[str, Any] | None = None
    luteal_length: dict[str, Any] | None = None
    confidence: float | None = Field(None, ge=0, le=1)


class Analyzer(ContractModel):
    code: str
    display_name: str
    description: str | None = None
    input_contracts: list[str] = Field(default_factory=list)
    output_contract: str
    version: str
    evidence: list[EvidenceReference] = Field(default_factory=list)


class AnalysisResult(ContractModel):
    id: str
    analyzer_code: str
    analyzer_version: str
    subject_id: str
    generated_at: datetime
    result_type: str
    payload: dict[str, Any]
    evidence: list[EvidenceReference] = Field(default_factory=list)


class PmddEvaluationRequest(ContractModel):
    subject_id: str
    observations: list[ObservationEvent] = Field(default_factory=list)


class PmddSymptomCycleScore(ContractModel):
    code: str
    premenstrual_mean: float | None = Field(None, ge=1, le=6)
    postmenstrual_mean: float | None = Field(None, ge=1, le=6)
    premenstrual_max: int | None = Field(None, ge=1, le=6)
    postmenstrual_max: int | None = Field(None, ge=1, le=6)
    severe_premenstrual_day_count: int = Field(default=0, ge=0)
    relative_elevation: float | None = Field(None, ge=0)
    qualifies: bool = False


class PmddCycleEvaluation(ContractModel):
    onset_date: date
    premenstrual_coverage: float = Field(default=0, ge=0, le=1)
    postmenstrual_coverage: float = Field(default=0, ge=0, le=1)
    evaluable: bool = False
    core_symptom_count: int = Field(default=0, ge=0)
    total_symptom_count: int = Field(default=0, ge=0)
    impairment_count: int = Field(default=0, ge=0)
    core_symptom_rule_met: bool = False
    total_symptom_rule_met: bool = False
    impairment_rule_met: bool = False
    cycle_positive: bool = False
    qualifying_core_symptoms: list[str] = Field(default_factory=list)
    qualifying_secondary_symptoms: list[str] = Field(default_factory=list)
    qualifying_impairment_symptoms: list[str] = Field(default_factory=list)
    symptom_scores: list[PmddSymptomCycleScore] = Field(default_factory=list)


class PmddEvaluationResult(ContractModel):
    analyzer_code: Literal["pmdd_pattern_v1"]
    analyzer_version: str
    subject_id: str
    generated_at: datetime
    status: Literal["insufficient_data", "suppressed", "quiet", "activation", "pattern"]
    confidence: Literal["none", "low", "moderate", "high"]
    supporting_cycle_count: int = Field(default=0, ge=0)
    evaluable_cycle_count: int = Field(default=0, ge=0)
    rich_pattern_logged: bool = False
    pack_recommended: bool = False
    coverage: float = Field(default=0, ge=0, le=1)
    activation_score: float = Field(default=0, ge=0)
    diagnostic_framework: Literal["drsp_cpass_like"] = "drsp_cpass_like"
    scoring_method: Literal["range_of_scale_used_30pct"] = "range_of_scale_used_30pct"
    positive_cycle_count: int = Field(default=0, ge=0)
    meets_chronicity_rule: bool = False
    meets_drsp_content_rule: bool = False
    meets_drsp_impairment_rule: bool = False
    suppressors: list[str] = Field(default_factory=list)
    summary: str
    evidence_summary: str
    cycle_evaluations: list[PmddCycleEvaluation] = Field(default_factory=list)
    recommended_actions: list[str] = Field(default_factory=list)
    evidence: list[EvidenceReference] = Field(default_factory=list)


class PcosEvaluationRequest(ContractModel):
    subject_id: str
    observations: list[ObservationEvent] = Field(default_factory=list)
    years_since_menarche: float | None = Field(
        None,
        ge=0,
        le=60,
        description=(
            "Optional context used to apply 2023 International Evidence-based Guideline cycle-irregularity rules "
            "by reproductive age. Adolescent rules apply when <3 years post-menarche."
        ),
    )
    evaluated_at: datetime | None = Field(
        None,
        description="Optional anchor time for the rolling evaluation window. Defaults to now.",
    )
    evaluation_window_days: int = Field(
        default=365,
        ge=60,
        le=1825,
        description="Trailing window (days) of observations used for cycle and feature derivation.",
    )


PcosCycleClassification = Literal[
    "regular",
    "irregular",
    "amenorrhea",
    "pubertal_transition",
    "insufficient_data",
]

PcosAgeRule = Literal[
    "pubertal_transition",
    "early_post_menarche",
    "adult",
    "default_adult",
]

PcosSeverity = Literal["none", "mild", "moderate", "severe"]


class PcosCycleIrregularitySignal(ContractModel):
    classification: PcosCycleClassification
    age_rule_applied: PcosAgeRule
    observed_cycle_count: int = Field(default=0, ge=0)
    observed_cycle_lengths: list[int] = Field(default_factory=list)
    longest_cycle_days: int | None = Field(None, ge=0)
    shortest_cycle_days: int | None = Field(None, ge=0)
    cycles_per_year_estimate: float | None = Field(None, ge=0)
    self_reported_regularity: Literal["regular", "variable", "infrequent", "absent", "unknown"] | None = None
    fallback_to_self_report: bool = False
    meets_irregularity_rule: bool = False
    rationale: str


class PcosHyperandrogenismSignal(ContractModel):
    acne_severity_max: PcosSeverity | None = None
    unwanted_hair_growth_max: PcosSeverity | None = None
    scalp_hair_thinning_max: PcosSeverity | None = None
    acne_persistent: bool = False
    hirsutism_persistent: bool = False
    scalp_thinning_persistent: bool = False
    qualifying_features: list[str] = Field(default_factory=list)
    persistent_feature_count: int = Field(default=0, ge=0)
    meets_hyperandrogenism_rule: bool = False
    rationale: str


class PcosMetabolicSignal(ContractModel):
    acanthosis_nigricans_reported: bool = False
    weight_observation_count: int = Field(default=0, ge=0)
    weight_kg_min: float | None = Field(None, ge=0)
    weight_kg_max: float | None = Field(None, ge=0)
    weight_kg_delta: float | None = None
    insulin_metabolic_note_count: int = Field(default=0, ge=0)
    glucose_lab_note_count: int = Field(default=0, ge=0)
    lipid_note_count: int = Field(default=0, ge=0)
    flags: list[str] = Field(default_factory=list)


PcosStatus = Literal[
    "insufficient_data",
    "suppressed",
    "features_absent",
    "features_partial",
    "features_present",
]


class PcosEvaluationResult(ContractModel):
    analyzer_code: Literal["pcos_feature_pattern_v1"]
    analyzer_version: str
    subject_id: str
    generated_at: datetime
    evaluation_window_start: date | None = None
    evaluation_window_end: date | None = None
    status: PcosStatus
    confidence: Literal["none", "low", "moderate", "high"]
    diagnostic_framework: Literal["rotterdam_2003_via_2023_ieg"] = "rotterdam_2003_via_2023_ieg"
    age_group_used: Literal["adolescent_pubertal", "adolescent_post", "adult", "unknown"]
    cycle_irregularity: PcosCycleIrregularitySignal
    hyperandrogenism: PcosHyperandrogenismSignal
    metabolic_context: PcosMetabolicSignal
    rotterdam_self_report_feature_count: int = Field(default=0, ge=0, le=2)
    meets_irregularity_rule: bool = False
    meets_hyperandrogenism_rule: bool = False
    pcom_assessment_could_resolve: bool = False
    adolescent_both_features_required: bool = False
    suppressors: list[str] = Field(default_factory=list)
    differential_reminders: list[str] = Field(default_factory=list)
    summary: str
    evidence_summary: str
    recommended_actions: list[str] = Field(default_factory=list)
    evidence: list[EvidenceReference] = Field(default_factory=list)


class Report(ContractModel):
    id: str
    subject_id: str
    generated_at: datetime
    report_type: Literal["clinician_summary", "csv_export", "fhir_export"]
    title: str
    summary: str | None = None
    included_event_ids: list[str] = Field(default_factory=list)
    included_projection_ids: list[str] = Field(default_factory=list)
    included_prediction_ids: list[str] = Field(default_factory=list)
    export_metadata: dict[str, Any] = Field(default_factory=dict)
    fhir_mapping: dict[str, Any] | None = None


class RecordLifecycle(ContractModel):
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None = None
    revision: int = Field(default=1, ge=1)
    sync_state: Literal["local_only", "exported", "imported"] = "local_only"


class LocalStoreMetadata(ContractModel):
    schema_version: str
    app_version: str | None = None
    device_timezone: str
    created_at: datetime
    updated_at: datetime
    last_exported_at: datetime | None = None
    notes: list[str] = Field(default_factory=list)


class LocalStoreSnapshot(ContractModel):
    metadata: LocalStoreMetadata
    subject: Subject
    tracker_settings: TrackerSettings
    observations: list[ObservationEvent] = Field(default_factory=list)
    cycle_projections: list[CycleProjection] = Field(default_factory=list)
    predictions: list[Prediction] = Field(default_factory=list)
    reports: list[Report] = Field(default_factory=list)
    record_lifecycle: dict[str, RecordLifecycle] = Field(default_factory=dict)


class LocalStoreSnapshotValidationRequest(ContractModel):
    snapshot: LocalStoreSnapshot


class LocalDataBundle(ContractModel):
    schema_version: str
    app_version: str | None = None
    exported_at: datetime
    subject: Subject
    tracker_settings: TrackerSettings | None = None
    observations: list[ObservationEvent] = Field(default_factory=list)
    cycle_projections: list[CycleProjection] = Field(default_factory=list)
    predictions: list[Prediction] = Field(default_factory=list)
    reports: list[Report] = Field(default_factory=list)


class LocalDataBundleValidationRequest(ContractModel):
    bundle: LocalDataBundle


class LocalDataBundleValidationResult(ContractModel):
    ok: bool
    status: Literal["accepted", "accepted_with_warnings", "unsupported_version"] = "accepted"
    errors: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    observation_results: list[ObservationValidationResult] = Field(default_factory=list)


class PrivacyManifestEntry(ContractModel):
    code: str
    display_name: str
    data_category: Literal["profile", "health", "derived", "export", "configuration", "research_fixture"]
    owner: Literal["device", "server", "developer"]
    leaves_device_by_default: bool
    server_persists: bool
    purpose: str
    notes: str | None = None


class PrivacyManifest(ContractModel):
    schema_version: str
    posture: Literal["local_first_private"] = "local_first_private"
    entries: list[PrivacyManifestEntry]


class AppConfig(ContractModel):
    app_name: str = "Period"
    api_version: str = "v1"
    contract_version: str
    privacy_posture: Literal["local_first_private"] = "local_first_private"
    calculation_owner: Literal["device", "server", "hybrid"] = "hybrid"
    supported_locales: list[str] = Field(default_factory=list)
    notes: list[str] = Field(default_factory=list)
