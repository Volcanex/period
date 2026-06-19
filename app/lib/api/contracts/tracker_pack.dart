/// Dart mirror of `core.contracts.TrackerPack`. Packs group tracker codes
/// (e.g. `pcos_support` adds skin/hair/glucose trackers). The backend is
/// the source of truth.
library;

import 'package:flutter/foundation.dart';

import 'tracker_definition.dart';

@immutable
class TrackerPack {
  final String code;
  final String displayName;
  final String description;
  final List<String> trackerCodes;
  final bool enabledByDefault;
  final String? clinicalNote;
  final List<TrackerEvidence> evidence;

  const TrackerPack({
    required this.code,
    required this.displayName,
    required this.description,
    required this.trackerCodes,
    required this.enabledByDefault,
    required this.evidence,
    this.clinicalNote,
  });

  factory TrackerPack.fromJson(Map<String, dynamic> j) => TrackerPack(
    code: j['code'] as String,
    displayName: j['display_name'] as String,
    description: j['description'] as String? ?? '',
    trackerCodes: ((j['tracker_codes'] as List?) ?? const [])
        .cast<String>()
        .toList(growable: false),
    enabledByDefault: j['enabled_by_default'] as bool? ?? false,
    clinicalNote: j['clinical_note'] as String?,
    evidence: ((j['evidence'] as List?) ?? const [])
        .map(
          (e) => TrackerEvidence.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false),
  );
}
