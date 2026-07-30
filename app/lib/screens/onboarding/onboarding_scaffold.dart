import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 16),
          actions,
        ],
      ),
    );
  }
}
