import 'package:flutter/foundation.dart';

enum CareCueKind { supportPack, cycleSignal }

enum CareCueActionKind { openTrackerPack, openCycleHistory, none }

@immutable
class CareCueAction {
  final CareCueActionKind kind;
  final String label;
  final String? targetCode;

  const CareCueAction({
    required this.kind,
    required this.label,
    this.targetCode,
  });
}

/// Frontend contract for detector-backed insight cards.
///
/// The backend is not emitting these yet, so the Insights tab keeps this shape
/// dormant and renders an empty detector lane instead of sample claims. Later
/// detectors can fill the same fields with a score, evidence summary, and
/// action target without changing the card UI.
@immutable
class CareCue {
  final String id;
  final CareCueKind kind;
  final String eyebrow;
  final String title;
  final String body;
  final String evidenceSummary;
  final CareCueAction action;
  final String detectorKey;
  final String detectorStatus;
  final double? confidence;

  const CareCue({
    required this.id,
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.evidenceSummary,
    required this.action,
    required this.detectorKey,
    this.detectorStatus = 'detector pending',
    this.confidence,
  });
}
