import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import '../today/widgets/section_box.dart';
import 'widgets/base_stat_card.dart';

/// Insights tab — real local model status. Pattern cards stay hidden until
/// detector output exists; no frontend-only medical hints are surfaced here.
class InsightsScreen extends StatelessWidget {
  final CycleState cycleState;
  final int loggedDayCount;
  final Map<String, bool> packEnabled;
  final ValueChanged<String>? onOpenTrackerPack;
  final VoidCallback? onOpenCycleHistory;

  const InsightsScreen({
    super.key,
    required this.cycleState,
    required this.loggedDayCount,
    required this.packEnabled,
    this.onOpenTrackerPack,
    this.onOpenCycleHistory,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _modelStats(cycleState, loggedDayCount);

    return Column(
      children: [
        const TopBar(title: 'insights'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SectionBox(
                eyebrow: 'cycle model',
                bare: true,
                trailing: SectionAction(
                  label: cycleState.predictionSource,
                  muted: true,
                ),
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
                                  'next flow estimate',
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
                            '${cycleState.nextStart} – ${cycleState.nextEnd}',
                            style: Type.display(
                              size: 24,
                              weight: Tokens.fwMedium,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'most likely start ${cycleState.nextMode}. this estimate updates from bleeding logs on this device.',
                            style: Type.body(
                              size: 14,
                              color: Tokens.graphite2,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PredictionBand(state: cycleState),
                          if (cycleState.observationCount == 0) ...[
                            const SizedBox(height: 12),
                            Text(
                              'log bleeding days to move from the starter prior into your own cycle history.',
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
                        final w = (constraints.maxWidth - gap) / 2;
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
              ),
              const SizedBox(height: 22),

              Center(
                child: Text(
                  '[ patterns, not diagnoses ]',
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.08,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
    range: state.avgFlow ?? 'local setting',
  ),
  _BaseStat(
    label: 'observations',
    value: '${state.observationCount}',
    unit: '',
    range: '$loggedDayCount logged days',
  ),
  _BaseStat(
    label: 'prediction',
    value: state.confidence,
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
