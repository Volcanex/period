# Local Data Bundles

This directory owns validation helpers for local-first import/export bundle contracts and Flutter local store snapshots. It must not introduce persistence, sync, accounts, or server-side calculation ownership. Treat bundles as user-controlled payloads that Flutter can export, import, or validate for shape parity.

Validation should check contract integrity, subject consistency, lifecycle keys, and Atlas tracker compatibility. It should not infer cycle state, mutate observations, or store data.

## Flutter Local Store

Flutter should store a `LocalStoreSnapshot`-shaped graph on device: metadata, one subject, tracker settings, raw observations, client-derived projections, client-derived predictions, reports, and lifecycle metadata keyed by stable record IDs. IDs should be UUID-style stable identifiers, not derived from dates or tracker codes. The lifecycle object is future-proofing for import/export and possible sync; it is not a sync engine.
