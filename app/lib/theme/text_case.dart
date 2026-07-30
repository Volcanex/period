/// Sentence-cases a label for display.
///
/// Symptom labels, mood values and bleed labels are persisted verbatim in
/// `period.local_store.v1` and are matched lowercase when mapped to tracker
/// codes, so they stay lowercase in the data layer and are capitalised only at
/// the point they are drawn.
String displayCase(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
