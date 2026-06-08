#!/usr/bin/env python3
"""Period backend contract API."""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
import uvicorn

from core.api.v1 import router as v1_router
from core.contracts import (
    AnalysisResult,
    Analyzer,
    CalendarAnnotation,
    CalendarDay,
    CalendarFeed,
    CalendarRange,
    ContractVersion,
    ContractCompatibilityResult,
    ContractCompatibilityRequest,
    ContractChangelogEntry,
    CycleProjection,
    LocalDataBundle,
    LocalDataBundleValidationRequest,
    LocalDataBundleValidationResult,
    RecordLifecycle,
    LocalStoreSnapshot,
    LocalStoreSnapshotValidationRequest,
    LocalStoreMetadata,
    ObservationEvent,
    ObservationValidationRequest,
    ObservationValidationResult,
    Prediction,
    PrivacyManifest,
    PrivacyManifestEntry,
    Report,
    Subject,
    TrackerPack,
    TrackerPreference,
    TrackerSettings,
    TrackerSettingsResolutionRequest,
    TrackerSettingsValidationResult,
    ActiveTrackerCatalog,
)

app = FastAPI(
    title="Period",
    description="Backend-only contract skeleton for a local-first Flutter period tracking app. Device clients own primary calculations.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://period.gabrielpenman.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

app.include_router(v1_router, prefix="/api/v1")


def _schema_for(model: type) -> dict:
    if hasattr(model, "model_json_schema"):
        return model.model_json_schema(ref_template="#/components/schemas/{model}")
    return model.schema(ref_template="#/components/schemas/{model}")


def custom_openapi() -> dict:
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    components = schema.setdefault("components", {}).setdefault("schemas", {})
    for model in [
        Subject,
        ObservationEvent,
        CycleProjection,
        Prediction,
        Analyzer,
        AnalysisResult,
        CalendarAnnotation,
        CalendarRange,
        ContractVersion,
        ContractCompatibilityResult,
        ContractCompatibilityRequest,
        ContractChangelogEntry,
    ContractVersion,
    ContractCompatibilityResult,
    ContractCompatibilityRequest,
    ContractChangelogEntry,
        CalendarDay,
        CalendarFeed,
        Report,
        TrackerPack,
    TrackerPreference,
    TrackerSettings,
    TrackerSettingsResolutionRequest,
    TrackerSettingsValidationResult,
    ActiveTrackerCatalog,
        LocalDataBundle,
        LocalDataBundleValidationRequest,
        LocalDataBundleValidationResult,
        RecordLifecycle,
    RecordLifecycle,
        LocalStoreSnapshot,
        LocalStoreSnapshotValidationRequest,
    LocalStoreSnapshotValidationRequest,
    LocalStoreSnapshot,
    LocalStoreSnapshotValidationRequest,
        LocalStoreMetadata,
    LocalStoreMetadata,
        PrivacyManifest,
        PrivacyManifestEntry,
        ObservationValidationRequest,
        ObservationValidationResult,
    ]:
        components.setdefault(model.__name__, _schema_for(model))
    app.openapi_schema = schema
    return app.openapi_schema


app.openapi = custom_openapi


@app.get("/api/_health", tags=["system"])
async def health() -> dict[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8080"))
    reload_flag = os.environ.get("DEBUG", "").lower() in ("1", "true", "yes")
    uvicorn.run("server:app", host=host, port=port, reload=reload_flag)
