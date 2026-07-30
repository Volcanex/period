import 'package:flutter/material.dart';

import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// 52px top bar with optional eyebrow + lowercase title and trailing icons.
///
/// The bar itself is full-bleed so its rule spans the window, but its contents
/// are capped and centred on [contentMaxWidth] so the title lines up with the
/// page body underneath it.
class TopBar extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final List<Widget> trailing;
  final double contentMaxWidth;

  const TopBar({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing = const [],
    this.contentMaxWidth = Layout.readableMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Tokens.base,
        border: Border(bottom: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      // The gutter sits inside the capped column, not outside it, so the title
      // lands on the same left edge as a page body whose own padding is inside
      // its ContentPane. Outside, the two drift apart by the gutter as soon as
      // the cap binds.
      child: ContentPane(
        maxWidth: contentMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Text(
                        eyebrow!.toUpperCase(),
                        style: Type.eyebrow(),
                      ),
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
        ),
      ),
    );
  }
}
