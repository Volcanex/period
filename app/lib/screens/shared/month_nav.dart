import 'package:flutter/material.dart';

import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Month label and stepper, sized to sit directly above a month grid.
///
/// It belongs to the grid rather than to a top bar: it is the primary control
/// on any screen that shows one, and a control reads as minor when it is small
/// and parked away from the thing it changes. Null [onBack]/[onForward] render
/// the arrow inert rather than hiding it, so the row does not reflow at the
/// ends of the range.
class MonthNav extends StatelessWidget {
  final DateTime month;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const MonthNav({super.key, required this.month, this.onBack, this.onForward});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_monthNames[month.month]} ${month.year}',
            style: Type.display(
              size: 20,
              weight: Tokens.fwMedium,
              height: 1.1,
              letterSpacingEm: -0.01,
            ),
          ),
        ),
        _Arrow(icon: Ph.caretLeft, onTap: onBack, semantic: 'Previous month'),
        const SizedBox(width: 2),
        _Arrow(icon: Ph.caretRight, onTap: onForward, semantic: 'Next month'),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semantic;

  const _Arrow({required this.icon, this.onTap, required this.semantic});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantic,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(
                color: enabled
                    ? Tokens.graphite.withValues(alpha: 0.24)
                    : Tokens.borderSoft.withValues(alpha: 0.4),
                width: Tokens.bwHair,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: enabled
                  ? Tokens.ink
                  : Tokens.graphite2.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
