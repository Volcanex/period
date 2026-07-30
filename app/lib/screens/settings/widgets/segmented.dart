import 'package:flutter/material.dart';

import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// Inline segmented control. Active = ink fill / paper text. Used for
/// theme, units, etc. Compact: each cell sizes to its label.
class Segmented extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const Segmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(v),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: Tokens.durFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: v == selected ? Tokens.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(Tokens.r1),
                  ),
                  child: Text(
                    displayCase(v),
                    style: Type.mono(
                      size: 11,
                      color: v == selected ? Tokens.paper : Tokens.graphite2,
                      letterSpacingEm: 0.04,
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
