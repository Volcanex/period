# Contracts

Contracts are canonical backend shapes for Flutter parity and OpenAPI. Models should be explicit, versionable, and conservative about uncertainty. Prefer adding evidence metadata over turning inferred reproductive-health states into unqualified facts.


Tracker packs and observation validation are public contracts. PCOS and similar feature areas must layer on universal ObservationEvent rather than inventing condition-specific event types.


## Versioning

Contract versions are date-stamped strings. Additive changes may add fields, endpoints, examples, or metadata while preserving valid existing payloads. Breaking changes remove or rename fields, change value semantics, or make previously valid payloads invalid. Flutter should treat unsupported versions as migration-required rather than silently coercing data.
