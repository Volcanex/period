# Atlas Tracking Bridge

Atlas is the internal bridge between backend contracts and future Flutter UI. It
owns tracker definitions, tracker packs, and observation validation. It does not
own frontend screens, local storage, diagnosis, or server-side calculations.

All logged data should flow through universal `ObservationEvent` objects.
Condition-specific experiences, including PCOS, are tracker packs layered on top
of the universal tracker registry rather than separate event systems.

## Temporal Coupling

Atlas owns temporal semantics: tracker grain, calendar layer, annotation date, optional range end, and priority. Flutter owns presentation: month/week layouts, colors, icons, gestures, and grouping. Keep calendar contracts data-shaped so the model and UI can consume the same observation timeline without coupling Atlas to frontend rendering.


## Personalization

Tracker settings are device-owned contracts. Atlas may provide defaults and stateless validation/resolution, but it must not become a backend profile store. Enabled packs, disabled trackers, pinned trackers, and display order exist to help Flutter assemble logging surfaces without forking the observation model.
