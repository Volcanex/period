# Period

Period is a backend-only FastAPI contract skeleton for a future Flutter app. It defines stable reproductive-health tracking data shapes, tiny API endpoints, OpenAPI, and fixtures that Flutter can mirror.

Period is local-first and private by default. The mobile client owns the product UX, user data store, and primary calculations. The backend owns contracts, validation boundaries, deployment shape, and a very small API surface.

## Quickstart

```bash
cd /root/work/Period
pip install -r requirements.txt
pytest
python3 server.py
```

OpenAPI is available at `http://127.0.0.1:8080/docs` when the server is running. The operational health endpoint is `/api/_health`; versioned app contracts start at `/api/v1`.

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
