# Period - Backend Contract Skeleton

Period is a backend-only FastAPI contract skeleton for a future Flutter app. Do not build product frontend here. The mobile client owns UX, local storage, and primary reproductive-health calculations. The backend owns stable schemas, OpenAPI, fixtures, validation boundaries, and tiny API endpoints.

## Non-Goals

- No HTML product frontend, page compiler, templates, or static site layer.
- No database, account system, sync engine, analytics pipeline, billing, or auth in this pass.
- No server-owned period prediction or ovulation calculation endpoints.
- No runnable analyzer plugin system yet.

## API Shape

Public routes stay intentionally small:

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

If future contracts include projections or predictions, treat them as client-derived data submitted or validated by shape. Do not add endpoints named like `/calculate-period` or `/predict-cycle` unless the product explicitly changes ownership of calculations.

## Contract Ownership

Pydantic models in `core/contracts/` are the backend source of truth. `AGENTS.md` files are canonical agent guidance and `CLAUDE.md` files are generated mirrors for Claude Code. Flutter should mirror them through OpenAPI and JSON examples in `contract_snapshot/`, plus test fixtures in `tests/fixtures/`. Contracts should preserve uncertainty: distinguish raw observations, imported data, inferred projections, and predictions.

## Core Model Research Baseline

The reference cycle model should follow a Bayesian hierarchical state-space posture: population priors shrink sparse individual histories, sequential updates refine a person's latent cycle-length state, and long apparent cycles may be modeled as self-tracking skip artifacts. The backend implementation is a reproducible reference for tests and Flutter parity, not the production calculation owner.

## Research Methodology: Evidence Ledger

Every tracker, analyzer, and report field should document source, assumption, confidence, version, and review status before it becomes product-critical. Observed data, user-entered data, imported data, inferred projections, and predictions are separate evidence categories. Clinical-sensitive states should remain marked as suspected unless confirmed by user-entered or imported evidence.

Analyzer contracts must be reproducible and versioned, but this skeleton does not implement clinical algorithms. Period is not a diagnostic device and does not provide medical diagnosis; contracts must carry uncertainty rather than flattening it away.

FHIR means Fast Healthcare Interoperability Resources in this project: a future healthcare data exchange mapping target. HealthKit and Health Connect are future mobile health platform mapping targets. All three are metadata-only here, not runtime dependencies or implemented adapters.

## Documentation Index

<!-- DOCS:START -->
| Path | Summary |
|------|---------|
| `contract_snapshot/AGENTS.md` | Contract Snapshot |
| `core/AGENTS.md` | Core Backend |
| `core/bundles/AGENTS.md` | Local Data Bundles |
| `core/contracts/AGENTS.md` | Contracts |
| `core/model/AGENTS.md` | Cycle Model |
| `core/privacy/AGENTS.md` | Privacy Manifest |
| `core/tracking/AGENTS.md` | Atlas Tracking Bridge |
| `tests/AGENTS.md` | Tests |

_Auto-compiled 2026-05-14 19:43 UTC - 8 doc(s) found._
<!-- DOCS:END -->

## Before Every Commit

1. Update relevant `AGENTS.md` files when project shape changes.
2. Run `python3 scripts/compile_docs.py` after adding, removing, or renaming `AGENTS.md` files. This also mirrors every `AGENTS.md` to `CLAUDE.md`.
3. Run `python3 scripts/sync_agent_docs.py --check` if you need a quick mirror check.
4. Run `pytest`.
5. For deploy confidence, run Docker-based tests when Docker is available.


## Flutter Frontend Readiness

The frontend should start from generated OpenAPI models plus `contract_snapshot/examples/`. The primary on-device graph is `LocalStoreSnapshot`; `LocalDataBundle` is an export/import boundary. Keep calculations and persistence on device. Backend validation is for contract confidence, not runtime ownership.
