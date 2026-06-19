import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// One cell in the base-stat 2×2 grid: eyebrow label, big value (+ optional
/// unit), and a muted-mono range/qualifier underneath.
class BaseStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String range;

  const BaseStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: Type.eyebrow(size: 10)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style:
                      Type.display(
                        size: 22,
                        weight: Tokens.fwMedium,
                        height: 1.05,
                        letterSpacingEm: -0.01,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: Type.body(
                      size: 13,
                      color: Tokens.graphite2,
                      height: 1.05,
                    ),
                  ),
              ],
            ),
          ),
          if (range.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              range,
              style: Type.mono(
                size: 10,
                color: Tokens.graphite2,
                letterSpacingEm: 0.04,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
