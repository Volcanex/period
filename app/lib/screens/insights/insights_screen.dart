import 'package:flutter/material.dart';

import '../../api/contracts/analyzer_results.dart';
import '../../data/models.dart';
import '../../theme/layout.dart';
import '../../theme/text_case.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import '../today/widgets/section_box.dart';
import 'widgets/base_stat_card.dart';
import 'widgets/pack_section.dart';

class InsightsScreen extends StatelessWidget {
  final CycleState cycleState;
  final int loggedDayCount;
  final Map<String, bool> packEnabled;
  final AnalyzerResults analyzerResults;
  final ValueChanged<String>? onOpenTrackerPack;
  final VoidCallback? onOpenCycleHistory;
  final VoidCallback? onRefreshAnalyzers;

  const InsightsScreen({
    super.key,
    required this.cycleState,
    required this.loggedDayCount,
    required this.packEnabled,
    required this.analyzerResults,
    this.onOpenTrackerPack,
    this.onOpenCycleHistory,
    this.onRefreshAnalyzers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Insights', contentMaxWidth: Layout.wideMax),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= Layout.twoColumnMin;
              return ContentPane(
                maxWidth: twoColumn ? Layout.wideMax : Layout.readableMax,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (twoColumn)
                      // The model reads as the subject and the analyzers as the
                      // commentary, so the split is 3:2 rather than even.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _cycleModel()),
                          const SizedBox(width: 22),
                          Expanded(flex: 2, child: _analyzers()),
                        ],
                      )
                    else ...[
                      _cycleModel(),
                      const SizedBox(height: 22),
                      _analyzers(),
                    ],

                    const SizedBox(height: 22),

                    Center(
                      child: Text(
                        '[ Patterns, not diagnoses ]',
                        style: Type.mono(
                          size: 10,
                          color: Tokens.graphite2,
                          letterSpacingEm: 0.08,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _analyzers() => _AnalyzerSection(
    results: analyzerResults,
    packEnabled: packEnabled,
    onOpenTrackerPack: onOpenTrackerPack,
    onRefresh: onRefreshAnalyzers,
  );

  Widget _cycleModel() {
    final stats = _modelStats(cycleState, loggedDayCount);

    return SectionBox(
      eyebrow: 'cycle model',
      bare: true,
      trailing: SectionAction(label: cycleState.predictionSource, muted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Next flow estimate',
                        style: Type.display(
                          size: 14,
                          weight: Tokens.fwMedium,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      cycleState.confidence.toUpperCase(),
                      style: Type.eyebrow(size: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  cycleState.nextStart == null
                      ? '—'
                      : '${cycleState.nextStart} – ${cycleState.nextEnd}',
                  style: Type.display(
                    size: 24,
                    weight: Tokens.fwMedium,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cycleState.nextStart == null
                      ? 'Log a period start, or add your last start date, and an estimate appears here.'
                      : 'Most likely start ${cycleState.nextMode}. This estimate updates from bleeding logs on this device.',
                  style: Type.body(
                    size: 14,
                    color: Tokens.graphite2,
                    height: 1.35,
                  ),
                ),
                // A band with no prediction behind it collapses to a
                // degenerate bar labelled "null" — drop it entirely.
                if (cycleState.nextStart != null) ...[
                  const SizedBox(height: 12),
                  _PredictionBand(state: cycleState),
                ],
                if (cycleState.observationCount == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Log bleeding days to move from the starter prior into your own cycle history.',
                    style: Type.body(
                      size: 13,
                      color: Tokens.graphite2,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              // Four across once each card still fits its range line;
              // two across on a phone.
              final cols = constraints.maxWidth >= 560 ? 4 : 2;
              final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in stats)
                    SizedBox(
                      width: w,
                      child: BaseStatCard(
                        label: s.label,
                        value: s.value,
                        unit: s.unit,
                        range: s.range,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---- condition analyzer section ----

class _AnalyzerSection extends StatelessWidget {
  final AnalyzerResults results;
  final Map<String, bool> packEnabled;
  final ValueChanged<String>? onOpenTrackerPack;
  final VoidCallback? onRefresh;

  const _AnalyzerSection({
    required this.results,
    required this.packEnabled,
    this.onOpenTrackerPack,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (results.state == AnalyzerLoadState.idle) {
      return _AnalyzerPrompt(onRefresh: onRefresh);
    }

    if (results.state == AnalyzerLoadState.error) {
      return _AnalyzerError(onRetry: onRefresh);
    }

    if (results.state == AnalyzerLoadState.unported) {
      return const _AnalyzerUnported();
    }

    final hasAnyCard =
        results.pcos != null ||
        results.pmdd != null ||
        results.perimenopause != null;

    // Only block on a spinner while nothing has come back yet. Once any
    // analyzer has landed we render its card and let the rest fill in.
    if (results.state == AnalyzerLoadState.loading && !hasAnyCard) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Tokens.graphite2,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (results.pcos != null)
          _ConditionCard(
            eyebrow: 'pcos · feature pattern',
            packCode: 'pcos_support',
            eval: results.pcos!,
            packEnabled: packEnabled['pcos_support'] ?? false,
            onOpenTrackerPack: onOpenTrackerPack,
          ),
        if (results.pmdd != null) ...[
          const SizedBox(height: 16),
          _ConditionCard(
            eyebrow: 'pms · pmdd · pattern',
            packCode: 'pms_pmdd_support',
            eval: results.pmdd!,
            packEnabled: packEnabled['pms_pmdd_support'] ?? false,
            onOpenTrackerPack: onOpenTrackerPack,
          ),
        ],
        if (results.perimenopause != null) ...[
          const SizedBox(height: 16),
          _ConditionCard(
            eyebrow: 'perimenopause · STRAW+10',
            packCode: 'perimenopause_support',
            eval: results.perimenopause!,
            packEnabled: packEnabled['perimenopause_support'] ?? false,
            onOpenTrackerPack: onOpenTrackerPack,
          ),
        ],
        if (results.state == AnalyzerLoadState.loading) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Analysing…',
              style: Type.mono(
                size: 10,
                color: Tokens.graphite2,
                letterSpacingEm: 0.04,
              ),
            ),
          ),
        ],
        if (results.state == AnalyzerLoadState.done) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRefresh,
                child: Text(
                  'Refresh ↻',
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.04,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shown while the condition analyzers still live only in the Python
/// reference implementation. Not an error and not a retry — there is nothing
/// on device to run yet, and saying so plainly beats an empty section.
class _AnalyzerUnported extends StatelessWidget {
  const _AnalyzerUnported();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condition patterns',
            style: Type.display(size: 13, weight: Tokens.fwMedium, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'PMDD, PCOS and perimenopause pattern analysis runs entirely on '
            'your device — it is still being built. Your logs are already '
            'being kept for it.',
            style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Shown when every analyzer call failed — an explicit error with a retry,
/// distinct from the idle "analyse now" prompt and from a legitimate empty
/// result, so the user knows the network failed rather than that nothing
/// was found.
class _AnalyzerError extends StatelessWidget {
  final VoidCallback? onRetry;
  const _AnalyzerError({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condition patterns',
            style: Type.display(size: 13, weight: Tokens.fwMedium, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            "Couldn't reach the on-device analyzers. Check your connection and try again.",
            style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Tokens.ink,
                  borderRadius: BorderRadius.circular(Tokens.r1),
                ),
                child: Text(
                  'Try again',
                  style: Type.mono(
                    size: 12,
                    color: Tokens.paper,
                    letterSpacingEm: 0.02,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzerPrompt extends StatelessWidget {
  final VoidCallback? onRefresh;
  const _AnalyzerPrompt({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condition patterns',
            style: Type.display(size: 13, weight: Tokens.fwMedium, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Run the on-device analyzers to check your logs for PCOS feature patterns, PMDD-style symptom clustering, and perimenopause staging.',
            style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Tokens.ink,
                  borderRadius: BorderRadius.circular(Tokens.r1),
                ),
                child: Text(
                  'Analyse now',
                  style: Type.mono(
                    size: 12,
                    color: Tokens.paper,
                    letterSpacingEm: 0.02,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final String eyebrow;
  final String packCode;
  final AnalyzerEval eval;
  final bool packEnabled;
  final ValueChanged<String>? onOpenTrackerPack;

  const _ConditionCard({
    required this.eyebrow,
    required this.packCode,
    required this.eval,
    required this.packEnabled,
    this.onOpenTrackerPack,
  });

  @override
  Widget build(BuildContext context) {
    final stats = eval.stats
        .map((s) => PackStat(label: s.label, value: s.value, sub: s.sub))
        .toList();

    String footer = eval.summary;
    if (eval.suppressors.isNotEmpty) {
      footer += '\n\nSuppressors: ${eval.suppressors.join(', ')}.';
    }
    if (eval.recommendedActions.isNotEmpty) {
      final action = eval.recommendedActions.first
          .toLowerCase()
          .replaceAll('_', ' ')
          .trim();
      // The backend action may already be a full sentence ending in a period;
      // don't append a second one.
      final period = action.endsWith('.') ? '' : '.';
      footer += '\n\nNext: $action$period';
    }

    return PackSection(
      eyebrow: eyebrow,
      on: packEnabled,
      glyph: Icons.analytics_outlined,
      stats: stats,
      footer: footer,
      painSeries: const [],
      onTurnOn: () => onOpenTrackerPack?.call(packCode),
    );
  }
}

// ---- prediction band ----

class _PredictionBand extends StatelessWidget {
  final CycleState state;
  const _PredictionBand({required this.state});

  @override
  Widget build(BuildContext context) {
    final bandWidth = state.bandEnd <= 0
        ? 0.0
        : ((state.bandEnd - state.bandStart) / state.bandEnd).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.r1),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Tokens.base),
                FractionallySizedBox(
                  widthFactor: state.bandEnd,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: bandWidth,
                    alignment: Alignment.centerRight,
                    child: Container(color: Tokens.phaseMenstrualSoft),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: state.todayPos,
                  alignment: Alignment.centerLeft,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(width: 2, color: Tokens.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TODAY · ${state.rangeStartLabel}    MODE · ${state.nextMode?.toUpperCase()}',
          style: Type.mono(
            size: 10,
            color: Tokens.graphite2,
            letterSpacingEm: 0.04,
          ),
        ),
      ],
    );
  }
}

// ---- stats ----

List<_BaseStat> _modelStats(CycleState state, int loggedDayCount) => [
  _BaseStat(
    label: 'cycle day',
    value: '${state.cycleDay ?? '—'}',
    unit: '',
    range: '${state.cycleLen} day cycle',
  ),
  _BaseStat(
    label: 'typical period',
    value: '${state.flowLen}',
    unit: 'days',
    range: state.avgFlow ?? 'Local setting',
  ),
  _BaseStat(
    label: 'observations',
    value: '${state.observationCount}',
    unit: '',
    range: '$loggedDayCount logged days',
  ),
  _BaseStat(
    label: 'prediction',
    value: displayCase(state.confidence),
    unit: '',
    range: _predictionRange(state),
  ),
];

String _predictionRange(CycleState state) {
  final window = state.predictedP80WindowDays;
  if (window == null) return state.predictionModelVersion;
  return '80% window ${window.round()} days';
}

class _BaseStat {
  final String label;
  final String value;
  final String unit;
  final String range;
  const _BaseStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.range,
  });
}
