# Period

Period is an open-source, local-first period tracking project. The goal is simple: reproductive-health tracking should not be locked behind a subscription, sold as surveillance, or treated as mysterious proprietary magic when the research exists and modern tooling can make careful software cheaper to build.

This repo is the backend contract skeleton for a future Flutter app. It defines stable reproductive-health tracking data shapes, tiny FastAPI endpoints, OpenAPI, and fixtures that Flutter can mirror.

Period is private and client-side by default. The mobile client owns the product UX, user data store, and primary calculations. The backend owns contracts, validation boundaries, deployment shape, and a very small API surface. Personal cycle history should not need to leave the device.

## Quickstart

```bash
cd /root/work/Period
pip install -r requirements.txt
pytest
python3 server.py
```

OpenAPI is available at `http://127.0.0.1:8080/docs` when the server is running. The operational health endpoint is `/api/_health`; versioned app contracts start at `/api/v1`.

## Why This Exists

Most period apps should not need to be paid products. A good tracker needs privacy, client-side storage, careful data modeling, a usable calendar, decent prediction methods, and honest uncertainty. None of that should require selling intimate health data or hiding basic cycle tools behind a subscription.

The research base is public enough to build from, and AI-assisted development makes it realistic for a small open project to turn that research into private, client-side software people can inspect, improve, and run. Period exists because this kind of tool should be out in the world: open source, locally private, and useful without pretending to be a doctor.

This is not a medical device and does not provide diagnosis. It should help people record observations, understand patterns, export summaries, and keep control of their own data.

## How It Works

Period is contract-first. The backend defines the shapes of the data and the Flutter app will own the experience of using them.

The core idea is:

1. Flutter stores the user's data on device as a `LocalStoreSnapshot`.
2. Daily logs are raw `ObservationEvent` records: bleeding, cramps, mood, temperature, notes, medication, and optional condition-support trackers.
3. Tracker definitions and tracker packs come from Atlas, the internal tracking bridge. Base symptoms are universal; PCOS, endometriosis, PMS/PMDD, perimenopause, and contraception are optional packs layered on the same observation model.
4. Cycle projections and predictions are client-derived shapes. The backend does not expose a `/predict` or `/calculate` endpoint because the user's cycle history should not need to leave the device.
5. The backend can validate contracts, export OpenAPI, publish example JSON, and check bundle compatibility. It does not store accounts, cycle history, analytics, or profiles. The app should work as private client-side software first.

The current model work includes a research-backed cycle-length baseline and backtesting utilities, but the production posture stays local-first: useful predictions, visible uncertainty, and no claim of clinical truth.

## Open Source Ethos

Period is open source because trust matters here. People should be able to see what is being tracked, how data is shaped, what assumptions are being made, and where uncertainty remains.

Contributions are welcome: code, research notes, tracker definitions, test data guidance, accessibility feedback, design critique, clinical-language review, Flutter implementation, docs, and careful bug reports. You do not need to be an expert to help. Clear questions, reproducible examples, and thoughtful review all count.

The project should stay aligned with a few principles:

- Private, client-side, local-first behavior by default.
- No selling or exploiting intimate health data.
- No fake certainty around predictions or suspected clinical states.
- Open contracts and reproducible tests.
- Useful free software before monetization.
- Respectful language for everyone who menstruates or tracks reproductive health.

## Docker

```bash
cp .env.example .env
docker compose up -d
```

Set `HOST_PORT` in `.env` when running alongside other projects. For a standalone Caddy deployment, set `DOMAIN` and `EMAIL`, then run:

```bash
docker compose --profile standalone up -d
```

## Contract Posture

- No frontend lives in this repo.
- No database, account system, analytics pipeline, or calculation engine exists in this skeleton.
- Cycle predictions and projections are client-derived shapes, not server-computed truth.
- FHIR, HealthKit, and Health Connect fields are mapping metadata only for now.


## API Surface

- `GET /api/_health`
- `GET /api/v1/app-config`
- `GET /api/v1/contract-version`
- `POST /api/v1/contract-compatibility`
- `GET /api/v1/tracker-definitions`
- `GET /api/v1/tracker-packs`
- `GET /api/v1/privacy-manifest`
- `GET /api/v1/tracker-settings/default`
- `POST /api/v1/tracker-settings/resolve`
- `POST /api/v1/validate-observation`
- `POST /api/v1/validate-local-data-bundle`
- `POST /api/v1/validate-local-store-snapshot`

There are no server-owned calculation endpoints. Predictions and projections are contract shapes for client-derived data.

## Flutter Contract Snapshot

Run this inside the project container to refresh Flutter-facing artifacts:

```bash
docker compose run --name period-contract-export --entrypoint python app scripts/export_contracts.py
docker cp period-contract-export:/app/contract_snapshot/. contract_snapshot/
docker rm period-contract-export
```

The snapshot contains `contract_snapshot/openapi.v1.json` and representative JSON examples under `contract_snapshot/examples/`.


## Flutter Local Store

Flutter should treat `LocalStoreSnapshot` as the on-device object graph: `metadata`, one `subject`, `tracker_settings`, raw `observations`, client-derived `cycle_projections`, client-derived `predictions`, user-controlled `reports`, and `record_lifecycle` keyed by stable record IDs.

Use UUID-style stable IDs for user records. Do not derive IDs from dates, tracker codes, cycle numbers, or display order. Keep `created_at`, `updated_at`, optional `deleted_at`, `revision`, and `sync_state` as lifecycle metadata so import/export and future sync can reason about records without changing the health data contracts.

The backend may validate a submitted snapshot shape, but it does not store snapshots. The export bundle is a user-controlled subset derived from the local store.
