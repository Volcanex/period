import 'package:flutter/foundation.dart';

@immutable
class LocalObservationEvent {
  final String id;
  final String subjectId;
  final String trackerCode;
  final DateTime observedAt;
  final DateTime observedOn;
  final String source;
  final Object value;
  final String? unit;
  final Map<String, dynamic>? rawPayload;
  final String? note;

  const LocalObservationEvent({
    required this.id,
    required this.subjectId,
    required this.trackerCode,
    required this.observedAt,
    required this.observedOn,
    required this.value,
    this.source = 'user_entered',
    this.unit,
    this.rawPayload,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_id': subjectId,
    'tracker_code': trackerCode,
    'observed_at': observedAt.toIso8601String(),
    'observed_on': _dateKey(observedOn),
    'source': source,
    'value': value,
    'unit': unit,
    'raw_payload': rawPayload,
    'note': note,
  };
}

String _dateKey(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
