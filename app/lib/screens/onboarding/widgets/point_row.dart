import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// An icon and one short sentence. Used for the privacy list.
class PointRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const PointRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nudged down so the glyph sits on the first line's optical centre.
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: Tokens.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Type.body(size: 14, color: Tokens.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
