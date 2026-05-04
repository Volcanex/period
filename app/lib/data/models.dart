/// Local data shapes used by the Today screen.
///
/// These mirror constants in `today.jsx` and `main.jsx` from the design
/// handoff. They are demo fixtures, not contracts. The real on-device store
/// will be `LocalStoreSnapshot` from the backend repo's contracts/.
library;

class TrackerDef {
  final String id;
  final String name;
  final String unit;
  final String placeholder;
  final double step;
  final double defaultValue;
  final double min;
  final double max;
  final TrackerKind kind;

  const TrackerDef({
    required this.id,
    required this.name,
    required this.unit,
    required this.placeholder,
    this.step = 1,
    this.defaultValue = 0,
    this.min = 0,
    this.max = 0,
    this.kind = TrackerKind.numeric,
  });
}

enum TrackerKind { numeric, category }

const trackerDefs = <String, TrackerDef>{
  'bbt': TrackerDef(
    id: 'bbt',
    name: 'basal body temp',
    unit: '°F',
    placeholder: 'tap to log',
    step: 0.05,
    defaultValue: 97.6,
    min: 95,
    max: 100,
  ),
  'sleep': TrackerDef(
    id: 'sleep',
    name: 'sleep',
    unit: 'h',
    placeholder: 'tap to log',
    step: 0.25,
    defaultValue: 7.5,
    min: 0,
    max: 14,
  ),
  'weight': TrackerDef(
    id: 'weight',
    name: 'weight',
    unit: 'lb',
    placeholder: 'tap to log',
    step: 0.2,
    defaultValue: 142.0,
    min: 50,
    max: 400,
  ),
  'cervical': TrackerDef(
    id: 'cervical',
    name: 'cervical mucus',
    unit: '',
    placeholder: 'tap to log',
    kind: TrackerKind.category,
  ),
  'sex': TrackerDef(
    id: 'sex',
    name: 'sex',
    unit: '',
    placeholder: 'tap to log',
    kind: TrackerKind.category,
  ),
  'meds': TrackerDef(
    id: 'meds',
    name: 'meds & supps',
    unit: '',
    placeholder: 'tap to log',
    kind: TrackerKind.category,
  ),
};

const symptomsList = <String>[
  'cramps',
  'pelvic pain',
  'headache',
  'fatigue',
  'bloated',
  'tender',
  'nausea',
  'acne',
  'cravings',
  'low energy',
  'back pain',
];

const moods = <String>['low', 'neutral', 'good', 'anxious', 'irritable'];

enum BleedLevel { none, spot, light, med, heavy }

extension BleedLevelLabel on BleedLevel {
  String get label => switch (this) {
        BleedLevel.none => 'none',
        BleedLevel.spot => 'spotting',
        BleedLevel.light => 'light',
        BleedLevel.med => 'medium',
        BleedLevel.heavy => 'heavy',
      };

  String get value => switch (this) {
        BleedLevel.none => 'none',
        BleedLevel.spot => 'spot',
        BleedLevel.light => 'light',
        BleedLevel.med => 'med',
        BleedLevel.heavy => 'heavy',
      };
}

enum Severity { mild, moderate, severe }

extension SeverityLabel on Severity {
  String get label => switch (this) {
        Severity.mild => 'mild',
        Severity.moderate => 'moderate',
        Severity.severe => 'severe',
      };
}

class CycleState {
  final String key;
  final String eyebrow;
  final int? cycleDay;
  final int cycleLen;
  final String? nextStart;
  final String? nextEnd;
  final String? nextMode;
  final String confidence;
  final String? avg;
  final String? avgFlow;
  final int cycleCount;
  final double bandStart;
  final double bandEnd;
  final double modePos;
  final double todayPos;

  const CycleState({
    required this.key,
    required this.eyebrow,
    required this.cycleDay,
    required this.cycleLen,
    required this.nextStart,
    required this.nextEnd,
    required this.nextMode,
    required this.confidence,
    required this.avg,
    required this.avgFlow,
    required this.cycleCount,
    required this.bandStart,
    required this.bandEnd,
    required this.modePos,
    required this.todayPos,
  });
}

const cycleStates = <String, CycleState>{
  'midcycle': CycleState(
    key: 'midcycle',
    eyebrow: 'cycle day',
    cycleDay: 12,
    cycleLen: 28,
    nextStart: 'may 25',
    nextEnd: 'jun 1',
    nextMode: 'may 28',
    confidence: 'medium',
    avg: '29 days',
    avgFlow: '4.7 days',
    cycleCount: 7,
    bandStart: 0.62,
    bandEnd: 0.85,
    modePos: 0.74,
    todayPos: 0.4,
  ),
  'bleeding': CycleState(
    key: 'bleeding',
    eyebrow: 'cycle day',
    cycleDay: 2,
    cycleLen: 28,
    nextStart: 'may 28',
    nextEnd: 'jun 4',
    nextMode: 'may 31',
    confidence: 'medium',
    avg: '29 days',
    avgFlow: '4.7 days',
    cycleCount: 7,
    bandStart: 0.86,
    bandEnd: 1,
    modePos: 0.93,
    todayPos: 0.06,
  ),
  'late_luteal': CycleState(
    key: 'late_luteal',
    eyebrow: 'cycle day',
    cycleDay: 26,
    cycleLen: 28,
    nextStart: 'may 4',
    nextEnd: 'may 9',
    nextMode: 'may 6',
    confidence: 'high',
    avg: '29 days',
    avgFlow: '4.7 days',
    cycleCount: 7,
    bandStart: 0,
    bandEnd: 0.18,
    modePos: 0.07,
    todayPos: -0.05,
  ),
  'unknown': CycleState(
    key: 'unknown',
    eyebrow: 'cycle status unknown',
    cycleDay: null,
    cycleLen: 28,
    nextStart: null,
    nextEnd: null,
    nextMode: null,
    confidence: 'not enough data',
    avg: null,
    avgFlow: null,
    cycleCount: 1,
    bandStart: 0,
    bandEnd: 0,
    modePos: 0,
    todayPos: 0,
  ),
};

/// Phase classification mirrors today.jsx (lines 137–143).
enum CyclePhase { menstrual, follicular, ovulation, luteal }

CyclePhase phaseForDay(int day, int cycleLen) {
  final mid = (cycleLen / 2).round();
  if (day <= 5) return CyclePhase.menstrual;
  if (day < mid - 1) return CyclePhase.follicular;
  if (day <= mid + 1) return CyclePhase.ovulation;
  return CyclePhase.luteal;
}
