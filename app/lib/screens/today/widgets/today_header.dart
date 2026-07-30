import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import 'mini_ring.dart';

class TodayHeader extends StatelessWidget {
  final CycleState state;
  final DateTime today;
  final bool showMiniRing;

  const TodayHeader({
    super.key,
    required this.state,
    required this.today,
    this.showMiniRing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY', style: Type.eyebrow()),
                const SizedBox(height: 4),
                Text(
                  _formatDate(today),
                  style: Type.display(
                    size: 28,
                    weight: Tokens.fwMedium,
                    height: 1.0,
                    letterSpacingEm: -0.02,
                  ),
                ),
                if (state.cycleDay != null) ...[
                  const SizedBox(height: 4),
                  _PhaseLine(state: state),
                  const SizedBox(height: 6),
                  _CycleLine(state: state),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    'No cycle data yet',
                    style: Type.mono(
                      size: 12,
                      color: Tokens.graphite2,
                      letterSpacingEm: 0.02,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showMiniRing && state.cycleDay != null) ...[
            const SizedBox(width: 12),
            MiniRing(
              day: state.cycleDay!,
              cycleLen: state.cycleLen,
              flowLen: state.flowLen,
              size: 84,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseLine extends StatelessWidget {
  final CycleState state;
  const _PhaseLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = phaseForDay(state.cycleDay!, state.cycleLen);
    final tint = switch (phase) {
      CyclePhase.menstrual => Tokens.phaseMenstrual,
      CyclePhase.follicular => Tokens.phaseFollicular,
      CyclePhase.ovulation => Tokens.phaseOvulationDeep,
      CyclePhase.luteal => Tokens.phaseLutealDeep,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: tint,
            shape: BoxShape.circle,
            border: Border.all(
              color: Tokens.graphite.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: displayCase(phase.name),
                  style: Type.display(
                    size: 22,
                    weight: Tokens.fwMedium,
                    height: 1.1,
                    letterSpacingEm: -0.01,
                  ),
                ),
                TextSpan(
                  text: ' phase',
                  style: Type.display(
                    size: 22,
                    weight: Tokens.fwRegular,
                    color: Tokens.graphite2,
                    height: 1.1,
                    letterSpacingEm: -0.01,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CycleLine extends StatelessWidget {
  final CycleState state;
  const _CycleLine({required this.state});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Cycle ',
            style: Type.mono(
              size: 12,
              color: Tokens.graphite2,
              letterSpacingEm: 0.02,
            ),
          ),
          TextSpan(
            text: 'day ${state.cycleDay}',
            style: Type.mono(
              size: 12,
              color: Tokens.ink,
              weight: Tokens.fwMedium,
              letterSpacingEm: 0.02,
            ),
          ),
          TextSpan(
            text: ' of ${state.cycleLen}',
            style: Type.mono(
              size: 12,
              color: Tokens.graphite2,
              letterSpacingEm: 0.02,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}
