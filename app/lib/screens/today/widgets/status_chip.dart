import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class ConfidenceChip extends StatelessWidget {
  final String confidence;
  const ConfidenceChip({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (confidence) {
      'high' => Tokens.oxide,
      'medium' => Tokens.ink,
      _ => Tokens.graphite2,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.graphite, width: 1),
        borderRadius: BorderRadius.circular(Tokens.r1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            'CONFIDENCE · ${confidence.toUpperCase()}',
            style: Type.mono(
              size: 10,
              color: Tokens.ink,
              letterSpacingEm: 0.06,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
