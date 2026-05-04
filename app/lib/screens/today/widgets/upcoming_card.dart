import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class UpcomingCard extends StatelessWidget {
  final CycleState state;

  const UpcomingCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'next period',
                style: Type.display(
                  size: 15,
                  weight: Tokens.fwMedium,
                  height: 1.2,
                  letterSpacingEm: -0.01,
                ),
              ),
              Text(
                'CONF · ${state.confidence.toUpperCase()}',
                style: Type.mono(
                  size: 10,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UpcomingLine(state: state),
          const SizedBox(height: 12),
          _RangeBar(state: state),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Tokens.borderSoft, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BASED ON ${state.cycleCount} RECENT CYCLES',
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.06,
                    height: 1.0,
                  ),
                ),
                Text(
                  'NOT A PROMISE',
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.06,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingLine extends StatelessWidget {
  final CycleState state;
  const _UpcomingLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final body = Type.body(size: 14, height: 1.4);
    final em = Type.mono(
      size: 14,
      color: Tokens.ink,
      weight: Tokens.fwMedium,
      letterSpacingEm: 0.01,
      height: 1.4,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'likely around ', style: body),
          TextSpan(text: state.nextMode ?? '—', style: em),
          TextSpan(text: '\nwindow ', style: body),
          TextSpan(
            text: '${state.nextStart ?? '—'} – ${state.nextEnd ?? '—'}',
            style: em,
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final CycleState state;
  const _RangeBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56, // 18 top labels + 1px axis + 22 bottom labels + a little
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Inset axis 6px each side to match `margin: 18px 6px 22px`.
        final axisLeft = 6.0;
        final axisRight = 6.0;
        final axisWidth = w - axisLeft - axisRight;
        final axisY = 18.0;

        Widget posChild({
          required double frac,
          required Widget child,
        }) {
          final x = axisLeft + frac.clamp(0.0, 1.0) * axisWidth;
          return Positioned(left: x, top: 0, bottom: 0, child: child);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Edge date labels above axis ends.
            Positioned(
              left: axisLeft,
              top: 2,
              child: Text(
                'MAY 4',
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              right: axisRight,
              top: 2,
              child: Text(
                'JUN 4',
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ),

            // Axis line.
            Positioned(
              left: axisLeft,
              right: axisRight,
              top: axisY,
              child: Container(height: 1, color: Tokens.graphite),
            ),
            // Axis end ticks.
            Positioned(
              left: axisLeft,
              top: axisY - 2,
              child: Container(width: 1, height: 6, color: Tokens.graphite),
            ),
            Positioned(
              right: axisRight,
              top: axisY - 2,
              child: Container(width: 1, height: 6, color: Tokens.graphite),
            ),

            // Mid tick + label (May 19, halfway between May 4 and Jun 4).
            Positioned(
              left: axisLeft + axisWidth / 2,
              top: axisY - 3,
              child: Container(width: 1, height: 7, color: Tokens.graphite2),
            ),
            Positioned(
              left: axisLeft + axisWidth / 2 - 24, // approx-center 48px label
              top: axisY - 14,
              width: 48,
              child: Text(
                'MAY 19',
                textAlign: TextAlign.center,
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ),

            // Range band — oxide tinted.
            Positioned(
              left: axisLeft + state.bandStart * axisWidth,
              width: math.max(
                0.0,
                (state.bandEnd - state.bandStart) * axisWidth,
              ),
              top: axisY - 8,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Tokens.oxide.withValues(alpha: 0.18),
                  border: Border(
                    left: const BorderSide(color: Tokens.oxide, width: 1),
                    right: const BorderSide(color: Tokens.oxide, width: 1),
                  ),
                ),
              ),
            ),

            // Mode line — strong oxide vertical.
            Positioned(
              left: axisLeft + state.modePos * axisWidth - 0.75,
              top: axisY - 10,
              width: 1.5,
              height: 21,
              child: Container(color: Tokens.oxide),
            ),

            // Today dot + label.
            posChild(
              frac: state.todayPos.clamp(0.0, 1.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -3.5,
                    top: axisY - 3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Tokens.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -16, // approx-center 32px label
                    top: axisY + 9,
                    width: 32,
                    child: Text(
                      'TODAY',
                      textAlign: TextAlign.center,
                      style: Type.mono(
                        size: 9,
                        color: Tokens.ink,
                        letterSpacingEm: 0.06,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

