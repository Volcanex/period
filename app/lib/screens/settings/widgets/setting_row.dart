import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// A label + optional sub-meta on the left, an arbitrary trailing widget
/// (segmented control, toggle, mono action) on the right. Bottom rule.
class SettingRow extends StatelessWidget {
  final String label;
  final String? meta;
  final Widget? trailing;

  const SettingRow({super.key, required this.label, this.meta, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Type.body(size: 14, color: Tokens.ink)),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    style: Type.mono(
                      size: 10,
                      color: Tokens.graphite2,
                      letterSpacingEm: 0.04,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
