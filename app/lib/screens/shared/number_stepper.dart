import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Minus / value / plus, clamped to [min]..[max].
///
/// [large] switches to the onboarding presentation — a bigger target and a
/// display-weight number. With `large: false` this renders exactly as the
/// settings rows always have.
class NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;
  final bool large;

  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Tokens.base,
        border: Border.all(color: Tokens.borderSoft),
        borderRadius: BorderRadius.circular(Tokens.r2),
      ),
      padding: EdgeInsets.all(large ? 4 : 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepButton(
            icon: Icons.remove,
            large: large,
            onTap: value <= min ? null : () => onChanged(value - 1),
          ),
          SizedBox(
            width: large ? 108 : 46,
            child: large ? _largeValue() : _smallValue(),
          ),
          StepButton(
            icon: Icons.add,
            large: large,
            onTap: value >= max ? null : () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _smallValue() => Text(
    '$value$unit',
    textAlign: TextAlign.center,
    style: Type.mono(size: 11, color: Tokens.ink, letterSpacingEm: 0.04),
  );

  // Tabular figures, or the number jitters as it crosses 28 -> 29.
  Widget _largeValue() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        '$value',
        style: Type.display(
          size: 40,
          weight: Tokens.fwMedium,
          height: 1.0,
          letterSpacingEm: -0.02,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      if (unit.isNotEmpty) ...[
        const SizedBox(width: 4),
        Text(
          unit,
          style: Type.mono(size: 13, color: Tokens.graphite2, height: 1.0),
        ),
      ],
    ],
  );
}

class StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool large;

  const StepButton({
    super.key,
    required this.icon,
    this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: large ? 40 : 28,
          height: large ? 40 : 28,
          child: Icon(
            icon,
            size: large ? 20 : 15,
            color: onTap == null ? Tokens.graphite2 : Tokens.ink,
          ),
        ),
      ),
    );
  }
}
