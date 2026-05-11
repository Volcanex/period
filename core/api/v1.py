"""Versioned v1 contract endpoints."""

from fastapi import APIRouter

from core.analyzers import evaluate_pcos, evaluate_pmdd
from core.bundles import validate_local_data_bundle, validate_local_store_snapshot
from core.contracts import (
    AppConfig,
    ContractCompatibilityRequest,
    ContractCompatibilityResult,
    ContractVersion,
    LocalDataBundleValidationRequest,
    LocalDataBundleValidationResult,
    LocalStoreSnapshotValidationRequest,
    ObservationValidationRequest,
    ObservationValidationResult,
    PcosEvaluationRequest,
    PcosEvaluationResult,
    PmddEvaluationRequest,
    PmddEvaluationResult,
    PrivacyManifest,
    TrackerDefinition,
    TrackerPack,
    TrackerSettings,
    TrackerSettingsResolutionRequest,
    TrackerSettingsValidationResult,
)
from core.contracts.registry import app_config, tracker_definitions
from core.contracts.versioning import check_contract_compatibility, contract_version
from core.privacy import privacy_manifest
from core.tracking import default_tracker_settings, resolve_tracker_settings, tracker_packs, validate_observation_event

router = APIRouter(tags=["v1"])


@router.get("/app-config", response_model=AppConfig)
async def get_app_config() -> AppConfig:
    """Return tiny client configuration and contract metadata."""
    return app_config()


@router.get("/contract-version", response_model=ContractVersion)
async def get_contract_version() -> ContractVersion:
    """Return current contract version, support window, and changelog."""
    return contract_version()


@router.post("/contract-compatibility", response_model=ContractCompatibilityResult)
async def check_compatibility(request: ContractCompatibilityRequest) -> ContractCompatibilityResult:
    """Check whether a schema version is accepted by this backend contract."""
    return check_contract_compatibility(request.schema_version)


@router.get("/tracker-definitions", response_model=list[TrackerDefinition])
async def get_tracker_definitions() -> list[TrackerDefinition]:
    """Return canonical tracker definitions for client parity."""
    return tracker_definitions()


@router.get("/tracker-packs", response_model=list[TrackerPack])
async def get_tracker_packs() -> list[TrackerPack]:
    """Return Atlas tracker packs, including base symptoms and optional condition packs."""
    return tracker_packs()


@router.get("/tracker-settings/default", response_model=TrackerSettings)
async def get_default_tracker_settings(subject_id: str = "subject-demo") -> TrackerSettings:
    """Return default device-owned tracker settings for a subject id."""
    return default_tracker_settings(subject_id)


@router.post("/tracker-settings/resolve", response_model=TrackerSettingsValidationResult)
async def resolve_settings(request: TrackerSettingsResolutionRequest) -> TrackerSettingsValidationResult:
    """Validate tracker settings and resolve active tracker definitions without storing them."""
    return resolve_tracker_settings(request.settings)


@router.get("/privacy-manifest", response_model=PrivacyManifest)
async def get_privacy_manifest() -> PrivacyManifest:
    """Return the local-first privacy posture as a Flutter-readable contract."""
    return privacy_manifest()


@router.post("/validate-observation", response_model=ObservationValidationResult)
async def validate_observation(request: ObservationValidationRequest) -> ObservationValidationResult:
    """Validate a single observation against the Atlas tracker registry."""
    return validate_observation_event(request.event)


@router.post("/validate-local-store-snapshot", response_model=LocalDataBundleValidationResult)
async def validate_store_snapshot(request: LocalStoreSnapshotValidationRequest) -> LocalDataBundleValidationResult:
    """Validate Flutter's on-device local store snapshot without storing it."""
    return validate_local_store_snapshot(request.snapshot)


@router.post("/validate-local-data-bundle", response_model=LocalDataBundleValidationResult)
async def validate_bundle(request: LocalDataBundleValidationRequest) -> LocalDataBundleValidationResult:
    """Validate a local-first import/export bundle without storing it."""
    return validate_local_data_bundle(request.bundle)


@router.post("/analyzers/pmdd/evaluate", response_model=PmddEvaluationResult)
async def evaluate_pmdd_pattern(request: PmddEvaluationRequest) -> PmddEvaluationResult:
    """Evaluate recent observations for repeated PMDD-style late-luteal patterns."""
    return evaluate_pmdd(request.subject_id, request.observations)


@router.post("/analyzers/pcos/evaluate", response_model=PcosEvaluationResult)
async def evaluate_pcos_pattern(request: PcosEvaluationRequest) -> PcosEvaluationResult:
    """Evaluate self-tracked observations against the 2023 IEG PCOS feature pattern.

    This endpoint never diagnoses PCOS. It summarises whether self-reported cycle
    irregularity and clinical hyperandrogenism features are present, flags
    suppressors that confound interpretation, and lists differentials a clinician
    should rule out.
    """
    return evaluate_pcos(
        request.subject_id,
        request.observations,
        years_since_menarche=request.years_since_menarche,
        evaluated_at=request.evaluated_at,
        evaluation_window_days=request.evaluation_window_days,
    )
