"""Contract version and compatibility policy."""

from __future__ import annotations

from datetime import date

from core.contracts.domain import (
    ContractChangelogEntry,
    ContractCompatibilityResult,
    ContractVersion,
)

CURRENT_CONTRACT_VERSION = "2026.05.08"
SUPPORTED_CONTRACT_VERSIONS = [CURRENT_CONTRACT_VERSION]
MINIMUM_SUPPORTED_VERSION = CURRENT_CONTRACT_VERSION
COMPATIBILITY_POLICY = (
    "Additive changes may extend schemas, endpoints, examples, or enum-adjacent metadata without removing fields. "
    "Breaking changes remove or rename fields, change value semantics, or make previously valid payloads invalid. "
    "Flutter should accept additive versions with regeneration/tests and require an explicit migration for breaking versions."
)
CHANGELOG = [
    ContractChangelogEntry(
        version="2026.05.08",
        released_on=date(2026, 5, 8),
        change_type="additive",
        summary="Additive PMDD analyzer contracts and backend evaluation endpoint; calculation ownership clarified as hybrid.",
        migration_note="Clients may regenerate OpenAPI and optionally adopt the PMDD analyzer endpoint.",
    ),
    ContractChangelogEntry(
        version="2026.05.02",
        released_on=date(2026, 5, 2),
        change_type="initial",
        summary="Initial Period v1 backend contract skeleton: domain models, Atlas trackers, settings, calendar feed, privacy manifest, local bundle validation, and contract snapshots.",
        migration_note="No migration required; first supported contract version.",
    )
]


def contract_version() -> ContractVersion:
    return ContractVersion(
        current_version=CURRENT_CONTRACT_VERSION,
        supported_versions=SUPPORTED_CONTRACT_VERSIONS,
        minimum_supported_version=MINIMUM_SUPPORTED_VERSION,
        compatibility_policy=COMPATIBILITY_POLICY,
        changelog=CHANGELOG,
    )


def check_contract_compatibility(schema_version: str) -> ContractCompatibilityResult:
    if schema_version == CURRENT_CONTRACT_VERSION:
        return ContractCompatibilityResult(
            schema_version=schema_version,
            status="accepted",
            current_version=CURRENT_CONTRACT_VERSION,
        )
    if schema_version in SUPPORTED_CONTRACT_VERSIONS:
        return ContractCompatibilityResult(
            schema_version=schema_version,
            status="accepted_with_warnings",
            current_version=CURRENT_CONTRACT_VERSION,
            warnings=["supported_legacy_contract_version"],
            migration_required=schema_version != CURRENT_CONTRACT_VERSION,
        )
    return ContractCompatibilityResult(
        schema_version=schema_version,
        status="unsupported_version",
        current_version=CURRENT_CONTRACT_VERSION,
        errors=["unsupported_contract_version"],
        migration_required=True,
    )
