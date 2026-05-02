# Core Backend

`core/` contains the FastAPI API modules and canonical Pydantic contracts. Keep this layer backend-only: no product UI, no HTML rendering, no local-first calculation implementation, and no persistence until explicitly planned.


Atlas lives in `core/tracking/` and is the bridge from contracts to future Flutter tracker UI. Add new features as tracker definitions or packs before adding API surface.
