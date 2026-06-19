import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// 28 micro-bars showing pain severity per cycle day. Each bar's height is
/// `severity / 4`, color tinted by the phase that day falls into.
class PainMap extends StatelessWidget {
  final List<int> values; // 0..4
  final int days;
  final int peakDay;

  const PainMap({
    super.key,
    required this.values,
    this.days = 28,
    this.peakDay = 14,
  });

  Color _tintFor(int day) {
    if (day <= 5) return Tokens.phaseMenstrual;
    if (day < peakDay - 1) return Tokens.phaseFollicularEdge;
    if (day <= peakDay + 1) return Tokens.phaseOvulationDeep;
    return Tokens.phaseLutealDeep;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = values.length.clamp(1, days);
        const gap = 2.0;
        final barW = (constraints.maxWidth - gap * (n - 1)) / n;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < n; i++) ...[
              SizedBox(
                width: barW,
                child: _Bar(value: values[i], tint: _tintFor(i + 1)),
              ),
              if (i != n - 1) const SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final Color tint;
  const _Bar({required this.value, required this.tint});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 44.0;
        // Empty days still render a thin baseline so the absence reads.
        final h = value == 0 ? 2.0 : (value / 4) * maxH;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: h.clamp(2.0, maxH),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: value == 0 ? 0.18 : 0.85),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
