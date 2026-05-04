import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import 'top_bar.dart';

/// Generic placeholder for tabs that aren't built yet (calendar/insights/etc).
class StubScreen extends StatelessWidget {
  final String title;
  final String body;
  final String eyebrow;

  const StubScreen({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow = 'stub',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(title: title),
        Expanded(
          child: Container(
            color: Tokens.base,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: Tokens.graphite, width: Tokens.bwRule),
                      borderRadius: BorderRadius.circular(Tokens.r2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(eyebrow.toUpperCase(), style: Type.eyebrow()),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Type.display(size: 22, letterSpacingEm: -0.02, height: 1.1),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Type.body(size: 14, color: Tokens.graphite2, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
