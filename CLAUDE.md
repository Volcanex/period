# Period - Backend Contract and Modeling Platform

Period is a backend-first FastAPI platform for a future Flutter app. Do not build product frontend here. The mobile client still owns UX and local storage, but the backend may now own stable schemas, OpenAPI, fixtures, validation boundaries, tracker catalogs, derived signals, analyzers, and server-side reproductive-health models.

## Non-Goals

- No HTML product frontend, page compiler, templates, or static site layer.
- No database, account system, sync engine, analytics pipeline, billing, or auth in this pass.
- No clinician-facing diagnosis or treatment claims.
- No open-ended plugin system until analyzer/versioning boundaries are explicit.

## API Shape

Public routes may expand beyond validation-only surfaces when the backend becomes
the right owner for stable tracker semantics or reproducible models:

- `GET /api/_health` for operational health.
- `GET /api/v1/app-config`
- `GET /api/v1/contract-version`
- `POST /api/v1/contract-compatibility` for tiny app/version metadata.
- `GET /api/v1/tracker-definitions` for canonical tracker definitions.
- `GET /api/v1/tracker-packs` for Atlas base and optional condition packs.
- `GET /api/v1/tracker-settings/default` for device-owned default personalization settings.
- `POST /api/v1/tracker-settings/resolve` for stateless active catalog resolution.
- `GET /api/v1/privacy-manifest` for local-first privacy posture.
- `POST /api/v1/validate-observation` for single-event contract validation.
- `POST /api/v1/validate-local-data-bundle` for user-controlled import/export validation.
- `POST /api/v1/validate-local-store-snapshot` for stateless Flutter local-store shape validation.
- `POST /api/v1/analyzers/pmdd/evaluate` for prospective DRSP/C-PASS-style PMDD pattern evaluation.
- `POST /api/v1/analyzers/pcos/evaluate` for self-report PCOS feature evaluation aligned to the 2023 International Evidence-based Guideline (non-diagnostic).
- `POST /api/v1/analyzers/perimenopause/evaluate` for STRAW+10 reproductive-aging stage estimation from self-tracked bleeding and symptoms (non-diagnostic).
- Future endpoints may include tracker-derived summaries, analyzer outputs, and reproducible model results when the backend is the canonical owner.

## Contract Ownership

Pydantic models in `core/contracts/` are the backend source of truth. `AGENTS.md` files are canonical agent guidance and `CLAUDE.md` files are generated mirrors for Claude Code. Flutter should mirror them through OpenAPI and JSON examples in `contract_snapshot/`, plus test fixtures in `tests/fixtures/`. Contracts should preserve uncertainty: distinguish raw observations, imported data, backend-derived signals, inferred projections, analyzer outputs, and predictions.

## Core Model Research Baseline

The reference cycle model should follow a Bayesian hierarchical state-space posture: population priors shrink sparse individual histories, sequential updates refine a person's latent cycle-length state, and long apparent cycles may be modeled as self-tracking skip artifacts. The backend implementation may now be the production calculation owner when a model is versioned, reproducible, and explicitly documented.

## Research Methodology: Evidence Ledger

Every tracker, analyzer, and report field should document source, assumption, confidence, version, and review status before it becomes product-critical. Observed data, user-entered data, imported data, backend-derived signals, inferred projections, analyzer outputs, and predictions are separate evidence categories. Clinical-sensitive states should remain marked as suspected unless confirmed by user-entered or imported evidence.

Analyzer contracts must be reproducible and versioned. Period is not a diagnostic device and does not provide medical diagnosis; contracts and models must carry uncertainty rather than flattening it away.

FHIR means Fast Healthcare Interoperability Resources in this project: a future healthcare data exchange mapping target. HealthKit and Health Connect are future mobile health platform mapping targets. All three are metadata-only here, not runtime dependencies or implemented adapters.

## Documentation Index

<!-- DOCS:START -->
| Path | Summary |
|------|---------|
| `contract_snapshot/AGENTS.md` | Contract Snapshot |
| `core/AGENTS.md` | Core Backend |
| `core/analyzers/AGENTS.md` | Analyzers |
| `core/bundles/AGENTS.md` | Local Data Bundles |
| `core/contracts/AGENTS.md` | Contracts |
| `core/model/AGENTS.md` | Cycle Model |
| `core/privacy/AGENTS.md` | Privacy Manifest |
| `core/tracking/AGENTS.md` | Atlas Tracking Bridge |
| `tests/AGENTS.md` | Tests |

_Auto-compiled 2026-06-08 12:13 UTC - 9 doc(s) found._
<!-- DOCS:END -->

## Before Every Commit

1. Update relevant `AGENTS.md` files when project shape changes.
2. Run `python3 scripts/compile_docs.py` after adding, removing, or renaming `AGENTS.md` files. This also mirrors every `AGENTS.md` to `CLAUDE.md`.
3. Run `python3 scripts/sync_agent_docs.py --check` if you need a quick mirror check.
4. Run `pytest`.
5. For deploy confidence, run Docker-based tests when Docker is available.


## Flutter Frontend Readiness

The frontend should start from generated OpenAPI models plus `contract_snapshot/examples/`. The primary on-device graph is `LocalStoreSnapshot`; `LocalDataBundle` is an export/import boundary. Backend endpoints may now provide canonical tracker catalogs, validation, derived summaries, and model outputs. Device persistence remains local unless product scope changes.
