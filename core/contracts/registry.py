"""Static contract registry for v1 API responses."""

from core.contracts.domain import AppConfig
from core.contracts.versioning import CURRENT_CONTRACT_VERSION
from core.tracking.registry import tracker_definitions


def app_config() -> AppConfig:
    return AppConfig(
        contract_version=CURRENT_CONTRACT_VERSION,
        calculation_owner="hybrid",
        supported_locales=["en-US"],
        notes=[
            "Flutter owns local storage and presentation; backend analyzers may own reproducible derived interpretations.",
            "Atlas owns tracker definitions, packs, and observation validation contracts.",
            "FHIR, HealthKit, and Health Connect mappings are metadata only in this skeleton.",
        ],
    )
