# Atlas Tracking Bridge

Atlas is the internal bridge between backend contracts and future Flutter UI. It
owns tracker definitions, tracker packs, and observation validation. It does not
own frontend screens, local storage, diagnosis, or server-side analyzer logic.

All logged data should flow through universal `ObservationEvent` objects.
Condition-specific experiences, including PCOS, are tracker packs layered on top
of the universal tracker registry rather than separate event systems.
Keep the registry organized as one universal base pack plus optional addon packs
so new tracking experiences can bolt on without new endpoint shapes or event
types.
Keep tracker definitions similarly split between universal definitions and
addon-oriented definitions, then compose them into the public catalog exported
to clients.
For PCOS-oriented tracking, prefer literature-backed domains from the 2023
international PCOS guideline: menstrual irregularity, hyperandrogenic features,
metabolic context, and uncertainty-preserving notes, without implying diagnosis.

## Temporal Coupling

Atlas owns temporal semantics: tracker grain, calendar layer, annotation date, optional range end, and priority. Flutter owns presentation: month/week layouts, colors, icons, gestures, and grouping. Keep calendar contracts data-shaped so the model and UI can consume the same observation timeline without coupling Atlas to frontend rendering.


## Personalization

Tracker settings are device-owned contracts. Atlas may provide defaults and stateless validation/resolution, but it must not become a backend profile store. Enabled packs, disabled trackers, pinned trackers, and display order exist to help Flutter assemble logging surfaces without forking the observation model.
