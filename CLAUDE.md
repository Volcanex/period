# Period - Backend Modeling Platform + Flutter Client

Period is a backend-first FastAPI platform plus a Flutter client (`app/`) sharing one repository. The backend owns stable schemas, OpenAPI, fixtures, validation boundaries, tracker catalogs, derived signals, analyzers, and server-side reproductive-health models. The Flutter client owns UX, local storage, and on-device rendering. Keep the two separated by directory: nothing in `app/` is imported from Python, and nothing in `core/`/`server.py` is coupled to Flutter.

## Repository Layout

- `core/`, `server.py`, `tests/` — Python backend (FastAPI, contracts, analyzers, model). Owns API shape, contracts, and server-side models.
- `app/` — Flutter client. Owns UX, on-device data, and product-facing rendering. Self-contained: its own `pubspec.yaml`, lints, tests.
- `contract_snapshot/` — JSON examples that both sides mirror against.

## Non-Goals

- No HTML product frontend, page compiler, templates, or static site layer in the Python tree. Product UI lives in `app/` (Flutter), not in Python templates.
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

_Auto-compiled 2026-07-30 09:50 UTC - 9 doc(s) found._
<!-- DOCS:END -->

## Before Every Commit

1. Update relevant `AGENTS.md` files when project shape changes.
2. Run `python3 scripts/compile_docs.py` after adding, removing, or renaming `AGENTS.md` files. This also mirrors every `AGENTS.md` to `CLAUDE.md`.
3. Run `python3 scripts/sync_agent_docs.py --check` if you need a quick mirror check.
4. Run `pytest`.
5. For deploy confidence, run Docker-based tests when Docker is available.


## Flutter Client (`app/`)

The Flutter client lives in `app/`. It implements the **Today** screen from the Sequence design handoff plus calendar, insights, settings, and tracker-management sections. Targets: web, iOS, Android, macOS, Windows, Linux.

**The client is offline-only and makes no network calls of any kind.** There is no HTTP dependency and no API client; the `http` package is deliberately absent from `pubspec.yaml`. Anything the client needs is either computed on device or shipped in the asset bundle. Do not reintroduce a network call without changing this section first — "local-first" here means "no server exists", not "server optional".

Consequences of that posture:

- **Tracker catalog** — bundled at `app/assets/catalog/{tracker_definitions,tracker_packs}.json`, generated from the Python registry by `scripts/export_catalog.py`. Re-run it after editing `core/tracking/registry.py`, or the bundled catalog silently drifts from the backend contract.
- **Cycle model** — `app/lib/model/cycle_model.dart` (`period-hierarchical-skip-v1`) already runs entirely on device.
- **Condition analyzers** — PMDD/PCOS/perimenopause still exist only as the Python reference implementation in `core/analyzers/`. The client reports `AnalyzerLoadState.unported` and says so in the insights tab. Porting them to Dart is the outstanding work; verify any port against the fixtures in `tests/fixtures/` so the two implementations cannot drift.

### First-run setup and the unknown-cycle rule

`lib/screens/onboarding/` is a four-step flow (privacy, last period start,
cycle length, tour) gated on `LocalPeriodStore.setupComplete` in
`app_shell.dart`'s `build()`. It replaces the shell rather than covering it, so
the tab bar is never built during setup.

**The rule it exists to enforce: the app must never invent a cycle.** Both data
questions are skippable, and skipping must produce an honest "we don't know"
state, not a plausible-looking guess.

- `LocalPeriodStore._cycleAnchor` is nullable. `cycleDayFor` and
  `cycleStateFor` return null / `_unknownCycleState()` when it is unset, and
  every screen already has an unknown branch. Logging any bleeding day recovers
  the anchor automatically through `_recalculateCycleModel`.
- `Clock.cycleAnchor` still falls back to `today - 3` so grid arithmetic has
  something to subtract. **That value is fabricated and must never reach the
  screen** — gate on `Clock.hasCycleAnchor` or use `cycleAnchorOrNull`. This is
  the one place the original bug can be reintroduced.
- `completeSetup` writes no bleeding log for the entered date. Inventing a flow
  level would file a guess as user-entered evidence, which the evidence-ledger
  rule above forbids.
- Persistence uses two explicit keys, `setupComplete` and `hasCycleAnchor`.
  `load()` defaults `setupComplete` to **true** for any blob it can decode, so
  existing installs are never sent back through setup, while the field default
  of false means a missing or corrupt blob is a first run.

Widget tests that boot `PeriodApp` must call `seedStore()` or they land in
setup instead of the shell.

Layout under `app/lib/`:

- `theme/tokens.dart` — direct port of the design's `colors_and_type.css` variables (palette, sky scale, phase tints, type scale, spacing, radii, motion).
- `theme/typography.dart` — three font families (Space Grotesk display, Inter body, JetBrains Mono) loaded via `google_fonts` for now; bake to assets when perf demands.
- `data/models.dart` — local fixtures: tracker defs, symptoms list, moods, bleed levels, cycle states, phase classification. They will be replaced by `LocalStoreSnapshot`-derived shapes from `contract_snapshot/`.
- `api/` — historical name; now the on-device catalog/analyzer repositories and their result contracts. No HTTP lives here.
- `theme/icons.dart` — Phosphor icons as `const IconData` against a subset font built by `scripts/subset_icon_font.py`. Adding an icon means adding it to that script's `ICONS` map and re-running it, or the code point renders blank. Do **not** add `phosphor_flutter`: it exposes icons as instance getters rather than const, which defeats `--tree-shake-icons` and ships ~2.6 MB of unused weights. The subset is under 3 KB.
- `screens/onboarding/` — first-run setup (see above).
- `screens/shared/` — top bar, tab bar, `NumberStepper`, `WeekdayHeader`.
- `state/` — app-level state and cross-tab wiring.
- `model/` — client-side model types.
- `screens/today/` — the Today screen, its widgets, and bottom sheets (including generic tracker sheets).
- `screens/calendar/`, `screens/insights/`, `screens/settings/`, `screens/trackers/` — the other tab destinations.
- `screens/shared/` — top bar, bottom tab bar, shared scaffolds.
- `app_shell.dart` — tab navigation and cross-tab state.

Toolchain notes: Flutter 3.44.x stable, SDK at `/opt/flutter` on h. `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`, `flutter build linux` all run from `app/`. Do not couple Flutter source to anything in `core/` or `tests/`.

Only web and Linux can be built on h. macOS builds need a Mac with Xcode, Windows builds need Windows with Visual Studio, and Android needs an SDK that is not installed here — those targets are scaffolded and compile-clean but unverified on this host.

**Asset-loading gotcha:** `TrackerCatalogRepository` reads its JSON with `AssetBundle.load` + an inline `utf8.decode`, *not* `loadString`. `loadString` hands any payload over ~50KB to a background isolate via `compute`, and `tracker_definitions.json` is ~70KB. That isolate never completes under widget tests' fake async, so the catalog comes back empty and every catalog-derived screen renders blank while the tests still look like ordinary assertion failures. Keep the inline decode.

Widget tests that assert on the Today tracker grid need a tall viewport (`tester.view.physicalSize`); the grid sits below the fold at the default 800x600 test surface and off-screen widgets are never built.

## Flutter Frontend Readiness (Contracts)

The Flutter client should grow toward generated OpenAPI models plus `contract_snapshot/examples/`. The primary on-device graph is `LocalStoreSnapshot`; `LocalDataBundle` is an export/import boundary. Keep calculations and persistence on device. Backend validation is for contract confidence, not runtime ownership. The current `app/lib/data/models.dart` fixtures are placeholders, not the contract surface.
