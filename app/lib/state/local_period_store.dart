import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/clock.dart';
import '../data/models.dart';
import '../model/cycle_model.dart';
import 'local_observation_event.dart';

const _storeKey = 'period.local_store.v1';

class DayLog {
  final BleedLevel? bleeding;
  final Map<String, Severity> symptoms;
  final Map<String, String> symptomNotes;
  final String? mood;
  final Map<String, double> numericValues;
  final Map<String, String> enumValues;
  final Map<String, bool> booleanValues;
  final Map<String, String> textValues;
  final String note;

  const DayLog({
    this.bleeding,
    this.symptoms = const {},
    this.symptomNotes = const {},
    this.mood,
    this.numericValues = const {},
    this.enumValues = const {},
    this.booleanValues = const {},
    this.textValues = const {},
    this.note = '',
  });

  bool get hasAnyLog =>
      bleeding != null ||
      symptoms.isNotEmpty ||
      mood != null ||
      numericValues.isNotEmpty ||
      enumValues.isNotEmpty ||
      booleanValues.isNotEmpty ||
      textValues.isNotEmpty ||
      note.trim().isNotEmpty;

  bool get hasFlow => bleeding != null && bleeding != BleedLevel.none;

  DayLog copyWith({
    BleedLevel? bleeding,
    bool clearBleeding = false,
    Map<String, Severity>? symptoms,
    Map<String, String>? symptomNotes,
    String? mood,
    bool clearMood = false,
    Map<String, double>? numericValues,
    Map<String, String>? enumValues,
    Map<String, bool>? booleanValues,
    Map<String, String>? textValues,
    String? note,
  }) {
    return DayLog(
      bleeding: clearBleeding ? null : bleeding ?? this.bleeding,
      symptoms: symptoms ?? this.symptoms,
      symptomNotes: symptomNotes ?? this.symptomNotes,
      mood: clearMood ? null : mood ?? this.mood,
      numericValues: numericValues ?? this.numericValues,
      enumValues: enumValues ?? this.enumValues,
      booleanValues: booleanValues ?? this.booleanValues,
      textValues: textValues ?? this.textValues,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    if (bleeding != null) 'bleeding': bleeding!.name,
    if (symptoms.isNotEmpty)
      'symptoms': symptoms.map((key, value) => MapEntry(key, value.name)),
    if (symptomNotes.isNotEmpty) 'symptomNotes': symptomNotes,
    if (mood != null) 'mood': mood,
    if (numericValues.isNotEmpty) 'numericValues': numericValues,
    if (enumValues.isNotEmpty) 'enumValues': enumValues,
    if (booleanValues.isNotEmpty) 'booleanValues': booleanValues,
    if (textValues.isNotEmpty) 'textValues': textValues,
    if (note.isNotEmpty) 'note': note,
  };

  static DayLog fromJson(Map<String, dynamic> json) {
    final symptomRaw =
        (json['symptoms'] as Map?)?.cast<String, dynamic>() ?? {};
    final symptomNoteRaw =
        (json['symptomNotes'] as Map?)?.cast<String, dynamic>() ?? {};
    final numericRaw =
        (json['numericValues'] as Map?)?.cast<String, dynamic>() ?? {};
    final enumRaw = (json['enumValues'] as Map?)?.cast<String, dynamic>() ?? {};
    final boolRaw =
        (json['booleanValues'] as Map?)?.cast<String, dynamic>() ?? {};
    final textRaw = (json['textValues'] as Map?)?.cast<String, dynamic>() ?? {};
    return DayLog(
      bleeding: _enumByName(BleedLevel.values, json['bleeding'] as String?),
      symptoms: {
        for (final entry in symptomRaw.entries)
          if (_enumByName(Severity.values, entry.value as String?) != null)
            entry.key: _enumByName(Severity.values, entry.value as String?)!,
      },
      symptomNotes: {
        for (final entry in symptomNoteRaw.entries)
          if (entry.value is String && (entry.value as String).isNotEmpty)
            entry.key: entry.value as String,
      },
      mood: json['mood'] as String?,
      numericValues: {
        for (final entry in numericRaw.entries)
          if (entry.value is num) entry.key: (entry.value as num).toDouble(),
      },
      enumValues: {
        for (final entry in enumRaw.entries)
          if (entry.value is String) entry.key: entry.value as String,
      },
      booleanValues: {
        for (final entry in boolRaw.entries)
          if (entry.value is bool) entry.key: entry.value as bool,
      },
      textValues: {
        for (final entry in textRaw.entries)
          if (entry.value is String) entry.key: entry.value as String,
      },
      note: json['note'] as String? ?? '',
    );
  }
}

class LocalPeriodStore extends ChangeNotifier {
  bool _loaded = false;

  /// Null means we genuinely do not know when the last period started — a
  /// fresh install, or someone who skipped that question during setup. It is
  /// deliberately nullable rather than defaulted: a placeholder date is
  /// indistinguishable from a real one at every call site, and inventing a
  /// cycle day is the exact bug this type is here to prevent.
  DateTime? _cycleAnchor;
  bool _setupComplete = false;
  int _cycleLen = Clock.cycleLen;
  int _flowLen = Clock.flowLen;
  int _ovPeak = Clock.ovPeak;
  Map<String, bool> _packEnabled = {};
  bool _darkMode = false;
  Map<String, DayLog> _logs = {};
  Map<String, String> _observationIds = {};
  int _idCounter = 0;

  bool get loaded => _loaded;
  DateTime? get cycleAnchor => _cycleAnchor;
  bool get hasCycleAnchor => _cycleAnchor != null;
  bool get setupComplete => _setupComplete;
  int get cycleLen => _cycleLen;
  int get flowLen => _flowLen;
  int get ovPeak => _ovPeak;
  Map<String, bool> get packEnabled => Map.unmodifiable(_packEnabled);
  bool get darkMode => _darkMode;
  List<LocalObservationEvent> get observations => _observations();
  int get observationCount => observations.length;
  int get loggedDayCount => _logs.values.where((log) => log.hasAnyLog).length;

  DayLog logFor(DateTime date) => _logs[_dateKey(date)] ?? const DayLog();

  Future<void> load() async {
    _cycleAnchor = Clock.cycleAnchor;
    final prefs = await SharedPreferences.getInstance();

    String? raw;
    try {
      raw = prefs.getString(_storeKey);
    } catch (e) {
      // The value under our key isn't a string — corrupt, or written by some
      // other writer (devtools, a future import path, a plugin format change).
      // getString() throws on a type mismatch, and that throw is what bricks
      // the boot. Drop the bad value so the app loads clean and self-heals.
      debugPrint('LocalPeriodStore: unreadable stored value, clearing: $e');
      await prefs.remove(_storeKey);
      raw = null;
    }
    if (raw != null) {
      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        // Anything we can decode belongs to someone who has already used the
        // app, including installs that predate this key — they must not be
        // sent back through setup. The field default is false, so only an
        // absent or unreadable blob counts as a first run.
        _setupComplete = json['setupComplete'] as bool? ?? true;
        if (json['hasCycleAnchor'] == false) {
          _cycleAnchor = null;
        } else {
          _cycleAnchor =
              _parseDate(json['cycleAnchor'] as String?) ?? _cycleAnchor;
        }
        _cycleLen = json['cycleLen'] as int? ?? _cycleLen;
        _flowLen = json['flowLen'] as int? ?? _flowLen;
        _ovPeak = json['ovPeak'] as int? ?? _ovPeak;
        _packEnabled =
            (json['packEnabled'] as Map?)?.cast<String, bool>() ?? _packEnabled;
        _darkMode = json['darkMode'] as bool? ?? _darkMode;
        _observationIds =
            (json['observationIds'] as Map?)?.cast<String, String>() ?? {};
        _idCounter = json['idCounter'] as int? ?? _idCounter;
        final logs = (json['logs'] as Map?)?.cast<String, dynamic>() ?? {};
        _logs = {
          for (final entry in logs.entries)
            entry.key: DayLog.fromJson(
              (entry.value as Map).cast<String, dynamic>(),
            ),
        };
      } catch (e, st) {
        debugPrint('LocalPeriodStore load failed, using defaults: $e\n$st');
      }
    }
    _recalculateCycleModel();
    _syncClock();
    _loaded = true;
    notifyListeners();
  }

  CycleState cycleStateFor(DateTime date) {
    final anchor = _cycleAnchor;
    if (anchor == null) return _unknownCycleState();

    final cycleDay = cycleDayFor(date);
    final prediction = _predictionFor(date);
    var nextAnchor = anchor.add(
      Duration(days: prediction.p50LengthDays.round()),
    );
    while (!nextAnchor.isAfter(date)) {
      nextAnchor = nextAnchor.add(
        Duration(days: prediction.p50LengthDays.round()),
      );
    }
    final windowStart = anchor.add(
      Duration(days: prediction.p10LengthDays.round()),
    );
    final windowEnd = anchor.add(
      Duration(days: prediction.p90LengthDays.round()),
    );
    final rangeStart = Clock.today;
    final rangeEnd = windowEnd.add(Duration(days: _flowLen));
    final totalDays = (rangeEnd.difference(rangeStart).inDays).clamp(1, 120);
    double pos(DateTime d) => d.difference(rangeStart).inDays / totalDays;
    final starts = _flowStarts();
    final source = starts.length >= 2 ? 'on-device model' : 'population prior';

    return CycleState(
      key: 'local',
      eyebrow: 'cycle day',
      cycleDay: cycleDay,
      cycleLen: _cycleLen,
      nextStart: _formatShort(windowStart),
      nextEnd: _formatShort(windowEnd),
      nextMode: _formatShort(nextAnchor),
      confidence: confidenceLabelForPrediction(
        prediction,
        cycleStartCount: starts.length,
      ),
      avg: '${prediction.expectedLengthDays.toStringAsFixed(1)} days',
      avgFlow: '$_flowLen days',
      cycleCount: _estimatedCycleCount(),
      bandStart: pos(windowStart).clamp(0.0, 1.0),
      bandEnd: pos(windowEnd).clamp(0.0, 1.0),
      modePos: pos(nextAnchor).clamp(0.0, 1.0),
      todayPos: pos(Clock.today).clamp(0.0, 1.0),
      rangeStartLabel: _formatAxis(rangeStart),
      rangeMidLabel: _formatAxis(
        rangeStart.add(Duration(days: totalDays ~/ 2)),
      ),
      rangeEndLabel: _formatAxis(rangeEnd),
      flowLen: _flowLen,
      predictionSource: source,
      predictionModelVersion: prediction.algorithmVersion,
      predictedP10LengthDays: prediction.p10LengthDays,
      predictedP50LengthDays: prediction.p50LengthDays,
      predictedP90LengthDays: prediction.p90LengthDays,
      predictedP80WindowDays: prediction.p80WindowDays,
      predictiveSdDays: prediction.predictiveSdDays,
      observationCount: observationCount,
    );
  }

  /// Null when there is no known anchor — the caller must show "unknown"
  /// rather than a number.
  int? cycleDayFor(DateTime date) {
    final anchor = _cycleAnchor;
    if (anchor == null) return null;
    final diff = _dateOnly(date).difference(anchor).inDays;
    final m = diff % _cycleLen;
    final mod = m < 0 ? m + _cycleLen : m;
    return mod + 1;
  }

  /// What we can honestly say with no anchor: the settings the user chose,
  /// and nothing about where they are in a cycle or when the next one starts.
  ///
  /// `cycleCount: 0` distinguishes this from "one cycle logged, still leaning
  /// on the population prior", which is a different message on Today.
  CycleState _unknownCycleState() => CycleState(
    key: 'local-unknown',
    eyebrow: 'cycle day',
    cycleDay: null,
    cycleLen: _cycleLen,
    nextStart: null,
    nextEnd: null,
    nextMode: null,
    confidence: 'starter',
    avg: null,
    avgFlow: null,
    cycleCount: 0,
    bandStart: 0,
    bandEnd: 0,
    modePos: 0,
    todayPos: 0,
    rangeStartLabel: null,
    rangeMidLabel: null,
    rangeEndLabel: null,
    flowLen: _flowLen,
    predictionSource: 'none',
    predictionModelVersion: '',
    observationCount: observationCount,
  );

  void setBleeding(DateTime date, BleedLevel level) {
    final key = _dateKey(date);
    _ensureObservationId(key, 'period_bleeding');
    final next = logFor(date).copyWith(bleeding: level);
    _setLog(key, next);
  }

  void setMood(DateTime date, String? mood) {
    final key = _dateKey(date);
    if (mood != null) _ensureObservationId(key, 'mood');
    final next = logFor(date).copyWith(mood: mood, clearMood: mood == null);
    _setLog(key, next);
  }

  void setSymptom(
    DateTime date,
    String symptom,
    Severity? severity, [
    String note = '',
  ]) {
    final key = _dateKey(date);
    final symptoms = {...logFor(date).symptoms};
    final notes = {...logFor(date).symptomNotes};
    if (severity == null) {
      symptoms.remove(symptom);
      notes.remove(symptom);
    } else {
      symptoms[symptom] = severity;
      final trimmed = note.trim();
      if (trimmed.isEmpty) {
        notes.remove(symptom);
      } else {
        notes[symptom] = trimmed;
      }
      _ensureObservationId(key, _trackerCodeForSymptom(symptom));
    }
    _setLog(
      key,
      logFor(date).copyWith(symptoms: symptoms, symptomNotes: notes),
    );
  }

  void setNumeric(DateTime date, String trackerId, double? value) {
    final key = _dateKey(date);
    final values = {...logFor(date).numericValues};
    if (value == null) {
      values.remove(trackerId);
    } else {
      values[trackerId] = value;
      _ensureObservationId(key, _trackerCodeForNumeric(trackerId));
    }
    _setLog(key, logFor(date).copyWith(numericValues: values));
  }

  void setEnumValue(DateTime date, String trackerCode, String? value) {
    final key = _dateKey(date);
    final values = {...logFor(date).enumValues};
    if (value == null) {
      values.remove(trackerCode);
    } else {
      values[trackerCode] = value;
      _ensureObservationId(key, trackerCode);
    }
    _setLog(key, logFor(date).copyWith(enumValues: values));
  }

  void setBooleanValue(DateTime date, String trackerCode, bool? value) {
    final key = _dateKey(date);
    final values = {...logFor(date).booleanValues};
    if (value == null) {
      values.remove(trackerCode);
    } else {
      values[trackerCode] = value;
      _ensureObservationId(key, trackerCode);
    }
    _setLog(key, logFor(date).copyWith(booleanValues: values));
  }

  void setTextValue(DateTime date, String trackerCode, String value) {
    final key = _dateKey(date);
    final values = {...logFor(date).textValues};
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      values.remove(trackerCode);
    } else {
      values[trackerCode] = trimmed;
      _ensureObservationId(key, trackerCode);
    }
    _setLog(key, logFor(date).copyWith(textValues: values));
  }

  void setNote(DateTime date, String note) {
    final key = _dateKey(date);
    if (note.trim().isNotEmpty) _ensureObservationId(key, 'note');
    _setLog(key, logFor(date).copyWith(note: note));
  }

  void setPackEnabled(String packCode, bool enabled) {
    _packEnabled = {..._packEnabled, packCode: enabled};
    _changed();
  }

  void setDarkMode(bool enabled) {
    _darkMode = enabled;
    _changed();
  }

  void setCycleLength(int days) {
    _applyCycleLength(days);
    _changed();
  }

  void setFlowLength(int days) {
    _applyFlowLength(days);
    _changed();
  }

  void _applyCycleLength(int days) {
    _cycleLen = days.clamp(21, 45);
    _ovPeak = (_cycleLen / 2).round().clamp(10, _cycleLen - 8);
  }

  void _applyFlowLength(int days) => _flowLen = days.clamp(1, 10);

  /// Records what first-run setup collected, in a single write.
  ///
  /// [lastPeriodStart] null means the user said they did not know. The anchor
  /// then stays unknown and nothing about a cycle day or a next period is
  /// invented — logging any bleeding day later recovers it automatically via
  /// [_recalculateCycleModel].
  ///
  /// [cycleLength] null means "not sure": the existing default stands rather
  /// than a guess being recorded as something the user told us.
  ///
  /// No bleeding log is written for [lastPeriodStart]. Doing so would invent a
  /// flow level nobody entered and file it as user-entered evidence.
  Future<void> completeSetup({
    DateTime? lastPeriodStart,
    int? cycleLength,
  }) async {
    if (cycleLength != null) _applyCycleLength(cycleLength);
    _cycleAnchor = lastPeriodStart == null
        ? null
        : _dateOnly(lastPeriodStart);
    _setupComplete = true;
    // Real logged starts outrank a self-reported date. Must run after the
    // anchor assignment or it would be clobbered.
    _recalculateCycleModel();
    _syncClock();
    notifyListeners();
    await _persist();
  }

  Future<void> resetDemoLogs() async {
    _logs = {};
    _observationIds = {};
    _idCounter = 0;
    // Not Clock.cycleAnchor — that would re-fabricate the demo anchor. With
    // the logs gone we no longer know when the last period started, and
    // setup itself is deliberately kept (see the settings copy).
    _cycleAnchor = null;
    _cycleLen = Clock.cycleLen;
    _flowLen = Clock.flowLen;
    _ovPeak = Clock.ovPeak;
    _changed();
  }

  Map<String, dynamic> exportSnapshot() => {
    'schema': 'period.local_snapshot.v1',
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'cycle': {
      'anchor': _cycleAnchor == null ? null : _dateKey(_cycleAnchor!),
      'lengthDays': _cycleLen,
      'flowLengthDays': _flowLen,
      'ovulationPeakDay': _ovPeak,
    },
    'preferences': {
      'darkMode': _darkMode,
      'enabledPacks': {
        for (final entry in _packEnabled.entries)
          if (entry.value) entry.key: true,
      },
    },
    'loggedDays': _logs.map((key, value) => MapEntry(key, value.toJson())),
    'observations': [for (final event in observations) event.toJson()],
  };

  void _setLog(String key, DayLog log) {
    if (log.hasAnyLog) {
      _logs = {..._logs, key: log};
    } else {
      _logs = {..._logs}..remove(key);
    }
    _recalculateCycleModel();
    _changed();
  }

  void _changed() {
    _syncClock();
    notifyListeners();
    unawaited(_persist());
  }

  void _syncClock() {
    Clock.overrideCycleConfig(
      anchor: _cycleAnchor,
      anchorKnown: _cycleAnchor != null,
      cycleLen: _cycleLen,
      flowLen: _flowLen,
      ovPeak: _ovPeak,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
    'setupComplete': _setupComplete,
    // Written explicitly rather than inferred from the key being absent:
    // older blobs have no cycleAnchor and still expect the legacy fallback.
    'hasCycleAnchor': _cycleAnchor != null,
    if (_cycleAnchor != null) 'cycleAnchor': _dateKey(_cycleAnchor!),
    'cycleLen': _cycleLen,
    'flowLen': _flowLen,
    'ovPeak': _ovPeak,
    'packEnabled': _packEnabled,
    'darkMode': _darkMode,
    'observationIds': _observationIds,
    'idCounter': _idCounter,
    'logs': _logs.map((key, value) => MapEntry(key, value.toJson())),
  };

  int _estimatedCycleCount() {
    final starts = _flowStarts();
    return starts.isEmpty ? 1 : starts.length.clamp(1, 12);
  }

  void _recalculateCycleModel() {
    final starts = _flowStarts();
    if (starts.isEmpty) return;

    final today = Clock.today;
    final startsOnOrBeforeToday = starts
        .where((date) => !date.isAfter(today))
        .toList(growable: false);
    _cycleAnchor = startsOnOrBeforeToday.isNotEmpty
        ? startsOnOrBeforeToday.last
        : starts.last;

    final intervals = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final days = starts[i].difference(starts[i - 1]).inDays;
      if (days >= 15 && days <= 120) intervals.add(days);
    }
    if (intervals.isNotEmpty) {
      final state = fitCycleModel(_observationsFromIntervals(intervals));
      final prediction = predictNextCycle(
        state,
        elapsedCycleDay: cycleDayFor(Clock.today),
      );
      _cycleLen = prediction.p50LengthDays.round().clamp(21, 45);
      _ovPeak = (_cycleLen / 2).round().clamp(10, _cycleLen - 8);
    }

    final runLengths = _flowRunLengths(starts);
    if (runLengths.length >= 2) {
      _flowLen = _roundedAverage(runLengths).clamp(1, 10);
    }
  }

  CyclePrediction _predictionFor(DateTime date) {
    final starts = _flowStarts();
    final intervals = <int>[];
    final skipped = <bool>[];
    for (var i = 1; i < starts.length; i++) {
      final days = starts[i].difference(starts[i - 1]).inDays;
      if (days >= 15 && days <= 120) {
        intervals.add(days);
        skipped.add(_skippedTrackingLikely(starts[i - 1], starts[i]));
      }
    }
    final state = fitCycleModel(_observationsFromIntervals(intervals, skipped));
    return predictNextCycle(state, elapsedCycleDay: cycleDayFor(date));
  }

  List<CycleLengthObservation> _observationsFromIntervals(
    List<int> intervals, [
    List<bool> skipped = const [],
  ]) {
    return [
      for (var i = 0; i < intervals.length; i++)
        CycleLengthObservation(
          cycleIndex: i,
          lengthDays: intervals[i],
          skippedTrackingSuspected: i < skipped.length && skipped[i],
        ),
    ];
  }

  List<DateTime> _flowStarts() {
    final flowDates = _flowDateSet().toList()..sort();
    final flowSet = flowDates.map(_dateKey).toSet();
    return [
      for (final date in flowDates)
        if (!flowSet.contains(_dateKey(date.subtract(const Duration(days: 1)))))
          date,
    ];
  }

  List<int> _flowRunLengths(List<DateTime> starts) {
    final flowSet = _flowDateSet().map(_dateKey).toSet();
    final lengths = <int>[];
    for (final start in starts) {
      var length = 0;
      var cursor = start;
      while (flowSet.contains(_dateKey(cursor))) {
        length += 1;
        cursor = cursor.add(const Duration(days: 1));
      }
      if (length > 0) lengths.add(length);
    }
    return lengths;
  }

  Set<DateTime> _flowDateSet() {
    return {
      for (final entry in _logs.entries)
        if (_isFlowLog(entry.value)) _parseDate(entry.key)!,
    };
  }

  bool _skippedTrackingLikely(DateTime previousStart, DateTime nextStart) {
    final days = nextStart.difference(previousStart).inDays;
    if (days < 42) return false;
    final observedInsideGap = _logs.entries.where((entry) {
      final date = _parseDate(entry.key);
      if (date == null || !entry.value.hasAnyLog) return false;
      return date.isAfter(previousStart.add(const Duration(days: 5))) &&
          date.isBefore(nextStart.subtract(const Duration(days: 5)));
    }).length;
    return observedInsideGap <= 1;
  }

  String _ensureObservationId(String dayKey, String trackerCode) {
    final key = '$dayKey|$trackerCode';
    final existing = _observationIds[key];
    if (existing != null) return existing;
    _idCounter += 1;
    final id =
        'obs-local-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_idCounter';
    _observationIds = {..._observationIds, key: id};
    return id;
  }

  List<LocalObservationEvent> _observations() {
    final events = <LocalObservationEvent>[];
    final entries = _logs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final observedOn = _parseDate(entry.key);
      if (observedOn == null) continue;
      final log = entry.value;
      final observedAt = DateTime(
        observedOn.year,
        observedOn.month,
        observedOn.day,
        12,
      );
      void add(String trackerCode, Object value, {String? unit, String? note}) {
        events.add(
          LocalObservationEvent(
            id: _ensureObservationId(entry.key, trackerCode),
            subjectId: 'subject-local-1',
            trackerCode: trackerCode,
            observedAt: observedAt,
            observedOn: observedOn,
            value: value,
            unit: unit,
            note: note,
          ),
        );
      }

      final bleeding = log.bleeding;
      if (bleeding != null) add('period_bleeding', bleeding.value);
      for (final symptom in log.symptoms.entries) {
        add(
          _trackerCodeForSymptom(symptom.key),
          symptom.value.name,
          note: log.symptomNotes[symptom.key],
        );
      }
      final mood = log.mood;
      if (mood != null) add('mood', mood);
      for (final numeric in log.numericValues.entries) {
        add(
          _trackerCodeForNumeric(numeric.key),
          numeric.value,
          unit: _unitForNumeric(numeric.key),
        );
      }
      for (final entry in log.enumValues.entries) {
        add(entry.key, entry.value);
      }
      for (final entry in log.booleanValues.entries) {
        add(entry.key, entry.value);
      }
      for (final entry in log.textValues.entries) {
        add(entry.key, entry.value);
      }
      if (log.note.trim().isNotEmpty) add('note', log.note.trim());
    }
    return events;
  }
}

bool _isFlowLog(DayLog log) {
  final b = log.bleeding;
  return b != null && b != BleedLevel.none;
}

int _roundedAverage(List<int> values) =>
    (values.reduce((a, b) => a + b) / values.length).round();

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

DateTime? _parseDate(String? value) {
  if (value == null) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _dateKey(DateTime d) {
  final date = _dateOnly(d);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String _trackerCodeForSymptom(String symptom) => switch (symptom) {
  'pelvic_pain' => 'pelvic_pain',
  'pelvic pain' => 'pelvic_pain',
  'pain with sex' => 'pain_with_sex',
  'headache' => 'migraine',
  'migraine or headache' => 'migraine',
  'tender' => 'breast_tenderness',
  'breast tenderness' => 'breast_tenderness',
  'bloated' => 'bloating',
  'bloating' => 'bloating',
  'acne' => 'acne_severity',
  'anxiety' => 'anxiety_severity',
  'depression' => 'depression_severity',
  'low energy' => 'energy',
  'unwanted hair growth' => 'hair_growth',
  _ => symptom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
};

String _trackerCodeForNumeric(String trackerId) => switch (trackerId) {
  'bbt' => 'basal_body_temperature',
  'sleep' => 'sleep_hours',
  _ => trackerId,
};

String? _unitForNumeric(String trackerId) => switch (trackerId) {
  'bbt' => 'fahrenheit',
  'basal_body_temperature' => 'fahrenheit',
  'sleep' => 'hours',
  'sleep_hours' => 'hours',
  'weight' => 'lb',
  _ => null,
};

String _formatShort(DateTime d) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month]} ${d.day}';
}

String _formatAxis(DateTime d) => _formatShort(d).toUpperCase();
