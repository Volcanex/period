import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import 'sheets/numeric_sheet.dart';
import 'sheets/symptom_sheet.dart';
import 'widgets/bleeding_card.dart';
import 'widgets/mood_row.dart';
import 'widgets/notes_section.dart';
import 'widgets/pinned_tracker_grid.dart';
import 'widgets/recent_pattern.dart';
import 'widgets/section_box.dart';
import 'widgets/status_chip.dart';
import 'widgets/symptoms_row.dart';
import 'widgets/today_header.dart';
import 'widgets/upcoming_card.dart';

/// Single screen mirror of `Sequence Today.html` from the design handoff.
class TodayScreen extends StatelessWidget {
  final CycleState cycleState;
  final List<String> pinnedTrackers;
  final bool showMiniRing;
  final bool compact;

  // logged state
  final BleedLevel? bleeding;
  final ValueChanged<BleedLevel> onBleedingChanged;
  final Map<String, Severity> symptoms;
  final void Function(String symptom, Severity? sev) onSymptomChanged;
  final String? mood;
  final ValueChanged<String?> onMoodChanged;
  final Map<String, double> numericValues;
  final void Function(String trackerId, double value) onNumericChanged;
  final String note;
  final ValueChanged<String> onNoteChanged;

  const TodayScreen({
    super.key,
    required this.cycleState,
    required this.pinnedTrackers,
    required this.showMiniRing,
    required this.compact,
    required this.bleeding,
    required this.onBleedingChanged,
    required this.symptoms,
    required this.onSymptomChanged,
    required this.mood,
    required this.onMoodChanged,
    required this.numericValues,
    required this.onNumericChanged,
    required this.note,
    required this.onNoteChanged,
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
        onSet: (sev) => onSymptomChanged(symptom, sev),
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

  @override
  Widget build(BuildContext context) {
    final hasCycleData = cycleState.cycleDay != null;
    final gap = compact ? 14.0 : 22.0;
    return Column(
      children: [
        TopBar(
          title: 'today',
          trailing: [
            Icon(PhosphorIcons.moonStars(), size: 18, color: Tokens.ink),
            Icon(PhosphorIcons.gearSix(), size: 18, color: Tokens.ink),
          ],
        ),
        Expanded(
          child: Container(
            color: Tokens.base,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
              children: [
                TodayHeader(
                  state: cycleState,
                  today: DateTime(2026, 5, 4),
                  showMiniRing: showMiniRing,
                ),
                SizedBox(height: gap - 18 + 4), // tighten — header eats some space
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ConfidenceChip(confidence: cycleState.confidence),
                  ],
                ),
                SizedBox(height: gap),
                BleedingCard(
                  value: bleeding,
                  onChanged: onBleedingChanged,
                ),
                if (pinnedTrackers.isNotEmpty) ...[
                  SizedBox(height: gap),
                  SectionBox(
                    eyebrow: 'pinned',
                    bare: true,
                    trailing: SectionAction(
                      label: 'edit',
                      onTap: () {
                        // No-op for now — would route to Trackers tab pin editor.
                      },
                    ),
                    child: PinnedTrackerGrid(
                      pinnedIds: pinnedTrackers,
                      values: numericValues,
                      onTap: (id) => _openNumeric(context, id),
                    ),
                  ),
                ],
                SizedBox(height: gap),
                SectionBox(
                  eyebrow: 'mood',
                  trailing: mood != null
                      ? SectionAction(
                          label: 'clear',
                          onTap: () => onMoodChanged(null),
                        )
                      : null,
                  child: MoodRow(
                    moods: moods,
                    selected: mood,
                    onChanged: onMoodChanged,
                  ),
                ),
                SizedBox(height: gap),
                SectionBox(
                  eyebrow: 'symptoms',
                  trailing: SectionAction(
                    label: 'tap to set severity',
                    muted: true,
                  ),
                  child: SymptomsRow(
                    symptoms: symptomsList,
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
                ),
                SizedBox(height: gap),
                SectionBox(
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
                ),
                if (hasCycleData) ...[
                  SizedBox(height: gap),
                  SectionBox(
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
                  ),
                ],
                SizedBox(height: gap),
                RecentPattern(state: cycleState),
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
                const SizedBox(height: 96), // breathing room above tab bar
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreSymptomsSheet extends StatelessWidget {
  const _MoreSymptomsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Tokens.paper,
          border: Border(top: BorderSide(color: Tokens.graphite, width: Tokens.bwRule)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.r3)),
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
                  'more symptoms',
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
              'enable additional trackers from the trackers tab. tracker packs add to this list — they do not change the model.',
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
                    side: const BorderSide(color: Tokens.graphite, width: Tokens.bwRule),
                  ),
                ),
                child: Text(
                  'got it',
                  style: Type.body(size: 14, weight: Tokens.fwMedium, height: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
