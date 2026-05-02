"""Local-first privacy manifest for Period v1 contracts."""

from __future__ import annotations

from core.contracts import PrivacyManifest, PrivacyManifestEntry

SCHEMA_VERSION = "2026.05.02"


def privacy_manifest() -> PrivacyManifest:
    return PrivacyManifest(
        schema_version=SCHEMA_VERSION,
        entries=[
            PrivacyManifestEntry(
                code="subject_profile",
                display_name="Subject profile",
                data_category="profile",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="Locale, timezone, consent, and coarse demographic contract fields for local app behavior.",
                notes="The backend defines the shape only; v1 does not store profiles.",
            ),
            PrivacyManifestEntry(
                code="observation_events",
                display_name="Observation events",
                data_category="health",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="Raw user-entered or imported health observations used by the on-device model and calendar.",
                notes="Validation endpoints are contract checks, not sync or storage.",
            ),
            PrivacyManifestEntry(
                code="cycle_projections",
                display_name="Cycle projections",
                data_category="derived",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="On-device derived cycle state snapshots, preserving uncertainty and suspected states.",
            ),
            PrivacyManifestEntry(
                code="predictions",
                display_name="Predictions",
                data_category="derived",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="Client-calculated next-period, ovulation, fertile-window, and luteal-length shapes.",
            ),
            PrivacyManifestEntry(
                code="reports",
                display_name="Reports and exports",
                data_category="export",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="Clinician summary, CSV export, and future FHIR export metadata controlled by the user.",
            ),
            PrivacyManifestEntry(
                code="tracker_catalog",
                display_name="Tracker catalog",
                data_category="configuration",
                owner="server",
                leaves_device_by_default=True,
                server_persists=False,
                purpose="Static tracker definitions and optional packs fetched by Flutter for parity.",
            ),
            PrivacyManifestEntry(
                code="tracker_settings",
                display_name="Tracker settings",
                data_category="configuration",
                owner="device",
                leaves_device_by_default=False,
                server_persists=False,
                purpose="User-selected packs, hidden trackers, and display preferences for local personalization.",
                notes="Resolve endpoints validate shape and return active catalogs without storing settings.",
            ),
            PrivacyManifestEntry(
                code="benchmark_fixtures",
                display_name="Benchmark fixtures",
                data_category="research_fixture",
                owner="developer",
                leaves_device_by_default=True,
                server_persists=False,
                purpose="Public or approved research data used in tests and model benchmark scripts.",
                notes="Not user app telemetry.",
            ),
        ],
    )
