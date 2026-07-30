import 'package:flutter/material.dart';

import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// Shared bottom-sheet shell: paper background, top hairline, drag handle,
/// title, close affordance, and a content slot. Pushes content above the
/// soft keyboard via MediaQuery viewInsets.
class SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const SheetScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: Tokens.paper,
            border: Border(
              top: BorderSide(color: Tokens.graphite, width: Tokens.bwRule),
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Tokens.r3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Tokens.graphite2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      displayCase(title),
                      style: Type.display(
                        size: 18,
                        weight: Tokens.fwMedium,
                        height: 1.1,
                        letterSpacingEm: -0.01,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'CLOSE',
                        style: Type.mono(
                          size: 11,
                          color: Tokens.graphite2,
                          letterSpacingEm: 0.06,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled "save" button matching the bottom-sheet primary action style.
class SheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Tokens.ink,
          foregroundColor: Tokens.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.r2),
            side: BorderSide(color: Tokens.ink, width: Tokens.bwRule),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: Type.body(
            size: 14,
            weight: Tokens.fwMedium,
            color: Tokens.paper,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
