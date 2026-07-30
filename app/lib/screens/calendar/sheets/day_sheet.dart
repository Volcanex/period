import 'package:flutter/material.dart';

import '../../../api/contracts/tracker_definition.dart';
import '../../../data/models.dart';
import '../../../state/local_period_store.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../today/widgets/bleeding_card.dart';
import '../../today/widgets/mood_row.dart';
import '../../today/widgets/notes_section.dart';
import '../../today/sheets/generic_tracker_sheet.dart';
import '../../today/sheets/sheet_scaffold.dart';
import '../../today/sheets/symptom_sheet.dart';

/// Bottom sheet shown when the user taps a calendar day. Read-only for now —
/// shows the date, current cycle position, and the kind of day (logged
/// flow, predicted flow, ovulation peak, today, plain). The "log here"
/// affordance routes back to Today for that date once retroactive logging
/// is wired up.
class DaySheet extends StatefulWidget {
  final DateTime date;
  final String phaseLabel;
  final String kindLabel;
  /// Null when no period start is known — the cycle-day line is hidden.
  final int? cycleDay;
  final DayLog log;
  final List<TrackerDefinition> activeDefinitions;
  final bool isToday;
  final bool isFuture;
  final ValueChanged<BleedLevel> onBleedingChanged;
  final void Function(String symptom, Severity? severity, String note)
  onSymptomChanged;
  final ValueChanged<String?> onMoodChanged;
  final void Function(String trackerId, double? value) onNumericChanged;
  final void Function(String trackerCode, String? value) onEnumChanged;
  final void Function(String trackerCode, bool? value) onBooleanChanged;
  final void Function(String trackerCode, String value) onTextChanged;
  final ValueChanged<String> onNoteChanged;

  const DaySheet({
    super.key,
    required this.date,
    required this.phaseLabel,
    required this.kindLabel,
    required this.cycleDay,
    required this.log,
    required this.activeDefinitions,
    required this.isToday,
    this.isFuture = false,
    required this.onBleedingChanged,
    required this.onSymptomChanged,
    required this.onMoodChanged,
    required this.onNumericChanged,
    required this.onEnumChanged,
    required this.onBooleanChanged,
    required this.onTextChanged,
    required this.onNoteChanged,
  });

  @override
  State<DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<DaySheet> {
  late BleedLevel? bleeding;
  late Map<String, Severity> symptoms;
  late String? mood;
  late Map<String, double> numericValues;
  late Map<String, String> enumValues;
  late Map<String, bool> booleanValues;
  late Map<String, String> textValues;
  late String note;

  @override
  void initState() {
    super.initState();
    bleeding = widget.log.bleeding;
    symptoms = {...widget.log.symptoms};
    mood = widget.log.mood;
    numericValues = {...widget.log.numericValues};
    enumValues = {...widget.log.enumValues};
    booleanValues = {...widget.log.booleanValues};
    textValues = {...widget.log.textValues};
    note = widget.log.note;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(widget.date);
    return SheetScaffold(
      title: dateText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('CYCLE POSITION', style: Type.eyebrow()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.phaseLabel.isEmpty
                            ? 'day log'
                            : '${widget.phaseLabel} phase',
                        style: Type.display(
                          size: 16,
                          weight: Tokens.fwMedium,
                          height: 1.1,
                        ),
                      ),
                      if (widget.cycleDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'cycle day ${widget.cycleDay}',
                          style: Type.mono(
                            size: 11,
                            color: Tokens.graphite2,
                            letterSpacingEm: 0.04,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.kindLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Tokens.base,
                      borderRadius: BorderRadius.circular(Tokens.r1),
                      border: Border.all(color: Tokens.borderSoft, width: 1),
                    ),
                    child: Text(
                      widget.kindLabel.toUpperCase(),
                      style: Type.mono(
                        size: 9,
                        color: Tokens.ink,
                        letterSpacingEm: 0.06,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.isFuture ? 'PROJECTED' : 'DAY LOG',
            style: Type.eyebrow(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            child: Text(
              _bodyText(),
              style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.isFuture)
            // Future days are projections — no log affordance. Show a muted
            // hint instead of a primary CTA so the sheet stays informational.
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                "[ can't log a day that hasn't happened yet ]",
                style: Type.mono(
                  size: 10,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.08,
                ),
              ),
            )
          else ...[
            BleedingCard(
              value: bleeding,
              onChanged: (level) {
                setState(() => bleeding = level);
                widget.onBleedingChanged(level);
              },
            ),
            const SizedBox(height: 14),
            Text('MOOD', style: Type.eyebrow()),
            const SizedBox(height: 8),
            MoodRow(
              moods: moods,
              selected: mood,
              onChanged: (value) {
                setState(() => mood = value);
                widget.onMoodChanged(value);
              },
            ),
            const SizedBox(height: 14),
            if (_loggableDefinitions.isNotEmpty) ...[
              Text('ACTIVE TRACKERS', style: Type.eyebrow()),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Tokens.bg,
                  borderRadius: BorderRadius.circular(Tokens.r2),
                  border: Border.all(color: Tokens.borderSoft, width: 1),
                ),
                child: Column(
                  children: [
                    for (final def in _loggableDefinitions)
                      _TrackerLogRow(
                        definition: def,
                        value: _valueLabel(def),
                        onTap: () => _openTracker(def),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text('NOTE', style: Type.eyebrow()),
            const SizedBox(height: 8),
            NotesSection(
              value: note,
              onChanged: (value) {
                setState(() => note = value);
                widget.onNoteChanged(value);
              },
            ),
            const SizedBox(height: 14),
            SheetPrimaryButton(
              label: 'done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  List<TrackerDefinition> get _loggableDefinitions => [
    for (final def in widget.activeDefinitions)
      if (!_handledInlineCodes.contains(def.code)) def,
  ];

  void _openTracker(TrackerDefinition def) {
    final symptom = _symptomForTracker(def.code);
    if (symptom != null) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Tokens.ink.withValues(alpha: 0.6),
        builder: (_) => SymptomSheet(
          symptom: symptom,
          current: symptoms[symptom],
          currentNote: widget.log.symptomNotes[symptom] ?? '',
          onSet: (severity, note) {
            setState(() {
              if (severity == null) {
                symptoms.remove(symptom);
              } else {
                symptoms[symptom] = severity;
              }
            });
            widget.onSymptomChanged(symptom, severity, note);
          },
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Tokens.ink.withValues(alpha: 0.6),
      builder: (_) => GenericTrackerSheet(
        definition: def,
        numericValue: numericValues[def.code],
        enumValue: enumValues[def.code],
        booleanValue: booleanValues[def.code],
        textValue: textValues[def.code],
        onNumericSet: (value) {
          setState(() {
            if (value == null) {
              numericValues.remove(def.code);
            } else {
              numericValues[def.code] = value;
            }
          });
          widget.onNumericChanged(def.code, value);
        },
        onEnumSet: (value) {
          setState(() {
            if (value == null) {
              enumValues.remove(def.code);
            } else {
              enumValues[def.code] = value;
            }
          });
          widget.onEnumChanged(def.code, value);
        },
        onBooleanSet: (value) {
          setState(() {
            if (value == null) {
              booleanValues.remove(def.code);
            } else {
              booleanValues[def.code] = value;
            }
          });
          widget.onBooleanChanged(def.code, value);
        },
        onTextSet: (value) {
          setState(() {
            final trimmed = value.trim();
            if (trimmed.isEmpty) {
              textValues.remove(def.code);
            } else {
              textValues[def.code] = trimmed;
            }
          });
          widget.onTextChanged(def.code, value);
        },
      ),
    );
  }

  String _valueLabel(TrackerDefinition def) {
    final symptom = _symptomForTracker(def.code);
    if (symptom != null) return symptoms[symptom]?.label ?? 'tap to log';
    final numeric = numericValues[def.code];
    if (numeric != null) {
      final unit = def.unit;
      return unit == null || unit.isEmpty
          ? _formatNumber(numeric)
          : '${_formatNumber(numeric)} $unit';
    }
    final enumValue = enumValues[def.code];
    if (enumValue != null) return enumValue.replaceAll('_', ' ');
    final boolValue = booleanValues[def.code];
    if (boolValue != null) return boolValue ? 'yes' : 'no';
    final textValue = textValues[def.code];
    if (textValue != null && textValue.trim().isNotEmpty) {
      return _shortText(textValue);
    }
    return 'tap to log';
  }

  String _bodyText() {
    if (widget.isFuture) {
      return 'this is a projection from the cycle model. nothing has been logged.';
    }
    if (widget.isToday) {
      return "today's main log also lives on the today tab.";
    }
    if (widget.log.hasAnyLog) {
      return 'saved locally on this device. edits here update the model immediately.';
    }
    return 'nothing logged yet. add bleeding here to backfill cycle history.';
  }

  static String _formatDate(DateTime d) {
    const wk = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const months = [
      '',
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return '${wk[d.weekday - 1]}, ${months[d.month]} ${d.day}';
  }
}

class _TrackerLogRow extends StatelessWidget {
  final TrackerDefinition definition;
  final String value;
  final VoidCallback onTap;

  const _TrackerLogRow({
    required this.definition,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logged = value != 'tap to log';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Tokens.borderSoft, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: logged ? Tokens.oxide : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Tokens.oxide, width: 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  definition.displayName.toLowerCase(),
                  style: Type.body(size: 14, color: Tokens.ink, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: Type.mono(
                    size: 10,
                    color: logged ? Tokens.ink : Tokens.graphite2,
                    letterSpacingEm: 0.04,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _handledInlineCodes = {'period_bleeding', 'mood', 'note'};

String? _symptomForTracker(String code) => switch (code) {
  'cramps' => 'cramps',
  'pelvic_pain' => 'pelvic pain',
  'migraine' => 'headache',
  'headache' => 'headache',
  'fatigue' => 'fatigue',
  'bloating' => 'bloated',
  'breast_tenderness' => 'tender',
  'nausea' => 'nausea',
  'acne_severity' => 'acne',
  'acne' => 'acne',
  'cravings' => 'cravings',
  'energy' => 'low energy',
  'back_pain' => 'back pain',
  _ => null,
};

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _shortText(String value) {
  final oneLine = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (oneLine.length <= 24) return oneLine;
  return '${oneLine.substring(0, 21)}...';
}
