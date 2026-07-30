import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Monday-first weekday initials sitting above a month grid.
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const days = ['m', 't', 'w', 't', 'f', 's', 's'];
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Center(
              child: Text(
                d.toUpperCase(),
                style: Type.mono(
                  size: 10,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
