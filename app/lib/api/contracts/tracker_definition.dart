/// Dart mirror of `core.contracts.TrackerDefinition` from the FastAPI
/// backend (see `core/contracts/`). The backend is the source of truth —
/// this file just shapes the JSON for type-safe access on the client.
///
/// Keep the field set strictly aligned with `/api/v1/tracker-definitions`
/// responses. New fields land here only after the contract version bumps.
library;

import 'package:flutter/foundation.dart';

@immutable
class TrackerDefinition {
  final String code;
  final String displayName;
  final String valueType; // enum, boolean, numeric, string, datetime, ...
  final String temporalGrain; // day, event, ...
  final String calendarLayer; // bleeding, symptom, mood, vital, ...
  final int calendarPriority;
  final String? unit;
  final List<String>? allowedValues;
  final Map<String, dynamic>? validationSchema;
  final Map<String, dynamic>? fhirMapping;
  final Map<String, dynamic>? healthkitMapping;
  final Map<String, dynamic>? healthConnectMapping;
  final String version;
  final List<TrackerEvidence> evidence;

  const TrackerDefinition({
    required this.code,
    required this.displayName,
    required this.valueType,
    required this.temporalGrain,
    required this.calendarLayer,
    required this.calendarPriority,
    required this.version,
    required this.evidence,
    this.unit,
    this.allowedValues,
    this.validationSchema,
    this.fhirMapping,
    this.healthkitMapping,
    this.healthConnectMapping,
  });

  factory TrackerDefinition.fromJson(
    Map<String, dynamic> j,
  ) => TrackerDefinition(
    code: j['code'] as String,
    displayName: j['display_name'] as String,
    valueType: j['value_type'] as String,
    temporalGrain: j['temporal_grain'] as String,
    calendarLayer: j['calendar_layer'] as String,
    calendarPriority: (j['calendar_priority'] as num).toInt(),
    unit: j['unit'] as String?,
    allowedValues: (j['allowed_values'] as List?)?.cast<String>(),
    validationSchema: (j['validation_schema'] as Map?)?.cast<String, dynamic>(),
    fhirMapping: (j['fhir_mapping'] as Map?)?.cast<String, dynamic>(),
    healthkitMapping: (j['healthkit_mapping'] as Map?)?.cast<String, dynamic>(),
    healthConnectMapping: (j['health_connect_mapping'] as Map?)
        ?.cast<String, dynamic>(),
    version: j['version'] as String,
    evidence: ((j['evidence'] as List?) ?? const [])
        .map(
          (e) => TrackerEvidence.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false),
  );

  bool get isNumeric => valueType == 'numeric' || valueType == 'decimal';
  bool get isEnum => valueType == 'enum';
  bool get isBoolean => valueType == 'boolean';
  bool get isText => valueType == 'string';
}

@immutable
class TrackerEvidence {
  final String source;
  final String assumption;
  final double confidence;
  final String version;
  final String reviewStatus;

  const TrackerEvidence({
    required this.source,
    required this.assumption,
    required this.confidence,
    required this.version,
    required this.reviewStatus,
  });

  factory TrackerEvidence.fromJson(Map<String, dynamic> j) => TrackerEvidence(
    source: j['source'] as String? ?? '',
    assumption: j['assumption'] as String? ?? '',
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
    version: j['version'] as String? ?? '',
    reviewStatus: j['review_status'] as String? ?? '',
  );
}
