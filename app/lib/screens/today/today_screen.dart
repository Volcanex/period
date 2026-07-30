import 'package:flutter/material.dart';

import '../../api/contracts/tracker_definition.dart';
import '../../data/clock.dart';
import '../../data/models.dart';
import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import 'sheets/generic_tracker_sheet.dart';
import 'sheets/numeric_sheet.dart';
import 'sheets/symptom_sheet.dart';
import 'widgets/bleeding_card.dart';
import 'widgets/mood_row.dart';
import 'widgets/notes_section.dart';
import 'widgets/recent_pattern.dart';
import 'widgets/section_box.dart';
import 'widgets/status_chip.dart';
import 'widgets/symptoms_row.dart';
import 'widgets/today_tracker_grid.dart';
import 'widgets/today_header.dart';
import 'widgets/upcoming_card.dart';

/// Single screen mirror of `Sequence Today.html` from the design handoff.
class TodayScreen extends StatelessWidget {
  final CycleState cycleState;
  final List<String> todayTrackers;
  final bool showMiniRing;
  final bool compact;

  // logged state
  final BleedLevel? bleeding;
  final ValueChanged<BleedLevel> onBleedingChanged;
  final Map<String, Severity> symptoms;
  final Map<String, String> symptomNotes;
  final List<String> symptomLabels;
  final void Function(String symptom, Severity? sev, String note)
  onSymptomChanged;
  final String? mood;
  final ValueChanged<String?> onMoodChanged;
  final Map<String, double> numericValues;
  final void Function(String trackerId, double? value) onNumericChanged;
  final Map<String, String> enumValues;
  final void Function(String trackerCode, String? value) onEnumChanged;
  final Map<String, bool> booleanValues;
  final void Function(String trackerCode, bool? value) onBooleanChanged;
  final Map<String, String> textValues;
  final void Function(String trackerCode, String value) onTextChanged;
  final Map<String, TrackerDefinition> catalogDefinitions;
  final String note;
  final ValueChanged<String> onNoteChanged;
  final bool darkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onOpenTrackers;
  final VoidCallback onOpenSettings;

  const TodayScreen({
    super.key,
    required this.cycleState,
    required this.todayTrackers,
    required this.showMiniRing,
    required this.compact,
    required this.bleeding,
    required this.onBleedingChanged,
    required this.symptoms,
    this.symptomNotes = const {},
    required this.symptomLabels,
    required this.onSymptomChanged,
    required this.mood,
    required this.onMoodChanged,
    required this.numericValues,
    required this.onNumericChanged,
    required this.enumValues,
    required this.onEnumChanged,
    required this.booleanValues,
    required this.onBooleanChanged,
    required this.textValues,
    required this.onTextChanged,
    required this.catalogDefinitions,
    required this.note,
    required this.onNoteChanged,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.onOpenTrackers,
    required this.onOpenSettings,
  });

  void _openSymptom(BuildContext context, String symptom) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Tokens.ink.withValues(alpha: 0.6),
      builder: (_) => SymptomSheet(
        symptom: symptom,
        current: symptoms[symptom],
        currentNote: symptomNotes[symptom] ?? '',
        onSet: (sev, note) => onSymptomChanged(symptom, sev, note),
      ),
    );
  }

  void _openNumeric(BuildContext context, String trackerId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Tokens.ink.withValues(alpha: 0.6),
      builder: (_) => NumericSheet(
        trackerId: trackerId,
        current: numericValues[trackerId],
        onSet: (v) => onNumericChanged(trackerId, v),
      ),
    );
  }

  void _openPinnedTracker(BuildContext context, String trackerId) {
    final catalogDef = catalogDefinitions[trackerId];
    if (_numericTrackerIds.contains(trackerId) ||
        (catalogDef?.isNumeric == true && trackerDefs[trackerId] != null)) {
      _openNumeric(context, trackerId);
      return;
    }
    final symptom = _symptomForTracker(trackerId);
    if (symptom != null) {
      _openSymptom(context, symptom);
      return;
    }
    if (trackerId == 'period_bleeding') {
      _showTrackerHint(context, 'Use the bleeding card above');
      return;
    }
    if (trackerId == 'mood') {
      _showTrackerHint(context, 'Use the mood row below');
      return;
    }
    if (trackerId == 'note') {
      _showTrackerHint(context, 'Use the note box below');
      return;
    }
    if (catalogDef != null &&
        (catalogDef.isNumeric ||
            catalogDef.isEnum ||
            catalogDef.isBoolean ||
            catalogDef.isText)) {
      _openGeneric(context, catalogDef);
      return;
    }
    _showTrackerHint(context, 'This tracker is on Today; logging UI is next');
  }

  void _openGeneric(BuildContext context, TrackerDefinition def) {
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
        onNumericSet: (v) => onNumericChanged(def.code, v),
        onEnumSet: (v) => onEnumChanged(def.code, v),
        onBooleanSet: (v) => onBooleanChanged(def.code, v),
        onTextSet: (v) => onTextChanged(def.code, v),
      ),
    );
  }

  void _showTrackerHint(BuildContext context, String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(text, style: Type.body(size: 13, color: Tokens.paper)),
        backgroundColor: Tokens.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only the compact layout carries a bottom tab bar to clear.
    final bottomGap = Layout.of(context) == Breakpoint.compact ? 96.0 : 24.0;
    return Column(
      children: [
        TopBar(
          title: 'Today',
          contentMaxWidth: Layout.wideMax,
          trailing: [
            _TopIconButton(
              icon: Icons.dark_mode_outlined,
              onTap: onToggleDarkMode,
            ),
            _TopIconButton(
              icon: Icons.settings_outlined,
              onTap: onOpenSettings,
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: Tokens.base,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumn = constraints.maxWidth >= Layout.twoColumnMin;
                return ContentPane(
                  maxWidth: twoColumn ? Layout.wideMax : Layout.readableMax,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    children: [
                      ...twoColumn
                          ? _twoColumnBody(context)
                          : _singleColumnBody(context),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '[ ON-DEVICE · NO ACCOUNT · NO CLOUD ]',
                          style: Type.mono(
                            size: 10,
                            color: Tokens.graphite2,
                            letterSpacingEm: 0.08,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: bottomGap),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  double get _gap => compact ? 14.0 : 22.0;

  bool get _hasCycleData => cycleState.cycleDay != null;

  List<Widget> _singleColumnBody(BuildContext context) => [
    ..._masthead(),
    SizedBox(height: _gap),
    _bleeding(),
    if (todayTrackers.isNotEmpty) ...[
      SizedBox(height: _gap),
      _trackers(context),
    ],
    SizedBox(height: _gap),
    _mood(),
    SizedBox(height: _gap),
    _symptoms(context),
    SizedBox(height: _gap),
    _note(),
    if (_hasCycleData) ...[SizedBox(height: _gap), _upcoming()],
    SizedBox(height: _gap),
    RecentPattern(state: cycleState),
  ];

  /// Desktop: logging on the left, what the model makes of it on the right.
  List<Widget> _twoColumnBody(BuildContext context) => [
    ..._masthead(),
    SizedBox(height: _gap),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _bleeding(),
              if (todayTrackers.isNotEmpty) ...[
                SizedBox(height: _gap),
                _trackers(context),
              ],
              SizedBox(height: _gap),
              _mood(),
              SizedBox(height: _gap),
              _symptoms(context),
            ],
          ),
        ),
        SizedBox(width: _gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _note(),
              if (_hasCycleData) ...[SizedBox(height: _gap), _upcoming()],
              SizedBox(height: _gap),
              RecentPattern(state: cycleState),
            ],
          ),
        ),
      ],
    ),
  ];

  List<Widget> _masthead() => [
    TodayHeader(
      state: cycleState,
      today: Clock.today,
      showMiniRing: showMiniRing,
    ),
    // tighten — header eats some space
    SizedBox(height: _gap - 18 + 4),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [ConfidenceChip(confidence: cycleState.confidence)],
    ),
  ];

  Widget _bleeding() =>
      BleedingCard(value: bleeding, onChanged: onBleedingChanged);

  Widget _trackers(BuildContext context) => SectionBox(
    eyebrow: 'trackers',
    bare: true,
    trailing: SectionAction(label: 'edit', onTap: onOpenTrackers),
    child: TodayTrackerGrid(
      trackerIds: todayTrackers,
      values: numericValues,
      symptoms: symptoms,
      mood: mood,
      bleeding: bleeding,
      enumValues: enumValues,
      booleanValues: booleanValues,
      textValues: textValues,
      catalogDefinitions: catalogDefinitions,
      onTap: (id) => _openPinnedTracker(context, id),
    ),
  );

  Widget _mood() => SectionBox(
    eyebrow: 'mood',
    trailing: mood != null
        ? SectionAction(label: 'clear', onTap: () => onMoodChanged(null))
        : null,
    child: MoodRow(moods: moods, selected: mood, onChanged: onMoodChanged),
  );

  Widget _symptoms(BuildContext context) => SectionBox(
    eyebrow: 'symptoms',
    trailing: SectionAction(label: 'tap to set severity', muted: true),
    child: SymptomsRow(
      symptoms: symptomLabels,
      values: symptoms,
      onTapSymptom: (s) => _openSymptom(context, s),
      onTapMore: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Tokens.ink.withValues(alpha: 0.6),
          builder: (_) => const _MoreSymptomsSheet(),
        );
      },
    ),
  );

  Widget _note() => SectionBox(
    eyebrow: 'note',
    trailing: note.isNotEmpty
        ? Text(
            'AUTOSAVED · JUST NOW',
            style: Type.mono(
              size: 10,
              color: Tokens.graphite2,
              letterSpacingEm: 0.08,
              height: 1.0,
            ),
          )
        : null,
    child: NotesSection(value: note, onChanged: onNoteChanged),
  );

  Widget _upcoming() => SectionBox(
    eyebrow: 'upcoming',
    bare: true,
    trailing: Text(
      'EST. WINDOW',
      style: Type.mono(
        size: 10,
        color: Tokens.graphite2,
        letterSpacingEm: 0.08,
        height: 1.0,
      ),
    ),
    child: UpcomingCard(state: cycleState),
  );
}

const _numericTrackerIds = {
  'bbt',
  'basal_body_temperature',
  'sleep',
  'sleep_hours',
  'weight',
};

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 18, color: Tokens.ink),
        ),
      ),
    );
  }
}

String? _symptomForTracker(String id) => switch (id) {
  'cramps' => 'cramps',
  'pelvic_pain' => 'pelvic pain',
  'pain_with_sex' => 'pain with sex',
  'anxiety_severity' => 'anxiety',
  'depression_severity' => 'depression',
  'irritability' => 'irritability',
  'hot_flashes' => 'hot flashes',
  'night_sweats' => 'night sweats',
  'vaginal_dryness' => 'vaginal dryness',
  'hair_growth' => 'unwanted hair growth',
  'hair_thinning' => 'hair thinning',
  'migraine' => 'headache',
  'headache' => 'headache',
  'fatigue' => 'fatigue',
  'bloating' => 'bloated',
  'breast_tenderness' => 'tender',
  'nausea' => 'nausea',
  'acne_severity' => 'acne',
  'energy' => 'low energy',
  'back_pain' => 'back pain',
  _ => null,
};

class _MoreSymptomsSheet extends StatelessWidget {
  const _MoreSymptomsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Tokens.paper,
          border: Border(
            top: BorderSide(color: Tokens.graphite, width: Tokens.bwRule),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Tokens.r3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Tokens.graphite2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'More symptoms',
                  style: Type.display(
                    size: 18,
                    weight: Tokens.fwMedium,
                    height: 1.1,
                    letterSpacingEm: -0.01,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'CLOSE',
                      style: Type.mono(
                        size: 11,
                        color: Tokens.graphite2,
                        letterSpacingEm: 0.06,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Enable additional trackers from the Trackers tab. Tracker packs add to this list — they do not change the model.',
              style: Type.body(size: 14, height: 1.55),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Tokens.bg,
                  foregroundColor: Tokens.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Tokens.r2),
                    side: BorderSide(
                      color: Tokens.graphite,
                      width: Tokens.bwRule,
                    ),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: Type.body(
                    size: 14,
                    weight: Tokens.fwMedium,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
