import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// One row in the tracker list. Pack state controls whether rows appear on
/// Today; individual rows are descriptive unless an explicit onTap is passed.
class TrackerRow extends StatelessWidget {
  final String leading;
  final String name;
  final String meta;
  final Widget trailing;
  final VoidCallback? onTap;

  const TrackerRow({
    super.key,
    required this.leading,
    required this.name,
    required this.meta,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Tokens.borderSoft, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (leading.isNotEmpty) ...[
                SizedBox(
                  width: 18,
                  child: Text(
                    leading,
                    style: Type.mono(size: 14, color: Tokens.graphite2),
                  ),
                ),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  name,
                  style: Type.body(size: 14, color: Tokens.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  meta.toUpperCase(),
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.06,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
