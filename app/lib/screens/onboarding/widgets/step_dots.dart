import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Page position for the tour. The active dot stretches into a short bar.
class StepDots extends StatelessWidget {
  final int count;
  final int current;

  const StepDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: Tokens.durBase,
              curve: Tokens.ease,
              width: i == current ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: i == current
                    ? Tokens.ink
                    : Tokens.graphite2.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(Tokens.r1),
              ),
            ),
          ),
      ],
    );
  }
}
