# Core Backend

`core/` contains the FastAPI API modules, canonical Pydantic contracts, tracker catalogs, and server-owned model/analyzer implementations. Keep this layer backend-only: no product UI, no HTML rendering, and no persistence until explicitly planned.


Atlas lives in `core/tracking/` and is the bridge from contracts to tracker semantics. Put tracker definitions, packs, and validation rules there; put derived interpretation logic in `core/analyzers/` or `core/model/` rather than in UI code.
