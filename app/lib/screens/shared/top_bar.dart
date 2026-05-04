import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// 52px top bar with optional eyebrow + lowercase title and trailing icons.
class TopBar extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final List<Widget> trailing;

  const TopBar({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Tokens.base,
        border: Border(bottom: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(eyebrow!.toUpperCase(), style: Type.eyebrow()),
                ),
              Text(
                title,
                style: Type.display(
                  size: 16,
                  weight: Tokens.fwMedium,
                  height: 1,
                  letterSpacingEm: -0.01,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < trailing.length; i++) ...[
                trailing[i],
                if (i != trailing.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
