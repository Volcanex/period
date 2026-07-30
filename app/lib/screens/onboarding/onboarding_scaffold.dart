import 'package:flutter/material.dart';

import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Shared page frame: eyebrow, title, optional body, scrolling content, and a
/// pinned action area at the bottom.
class OnboardingScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? body;
  final Widget? trailing;
  final Widget child;
  final Widget actions;

  const OnboardingScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.trailing,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final compact = Layout.of(context) == Breakpoint.compact;
    // On a phone the column fills the screen: the action sits at the bottom
    // where the thumb is. On anything larger, filling the viewport strands a
    // narrow column between two large voids, so the step becomes a card of its
    // natural height, centred, and the window is margin around it.
    final frame = Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 8, 20, 16)
          : const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: _body(compact),
    );

    if (compact) {
      return ContentPane(maxWidth: Layout.onboardingMax, child: frame);
    }

    return Center(
      child: AnimatedSize(
        duration: Tokens.durBase,
        curve: Tokens.ease,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Layout.onboardingCardMax,
            maxHeight: Layout.onboardingCardHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(
                color: Tokens.borderSoft,
                width: Tokens.bwHair,
              ),
            ),
            child: frame,
          ),
        ),
      ),
    );
  }

  Widget _body(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // The card takes the height of whatever step is showing rather than a
      // fixed one, so short steps have no dead space inside the border.
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(eyebrow.toUpperCase(), style: Type.eyebrow()),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Type.display(
            size: 28,
            weight: Tokens.fwMedium,
            height: 1.15,
            letterSpacingEm: -0.02,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 10),
          Text(
            body!,
            style: Type.body(size: 15, color: Tokens.graphite2, height: 1.5),
          ),
        ],
        const SizedBox(height: 22),
        if (compact)
          // Centred when the content is shorter than the space, scrolling when
          // it isn't — otherwise short steps leave a large gap above the
          // buttons on a tall phone.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(child: child),
                ),
              ),
            ),
          )
        else
          // Loose, so the card ends just below the content; the scroll view is
          // still there for the tallest step in a short window.
          Flexible(child: SingleChildScrollView(child: child)),
        SizedBox(height: compact ? 16 : 20),
        actions,
      ],
    );
  }
}
