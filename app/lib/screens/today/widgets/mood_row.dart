import 'package:flutter/material.dart';

import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class MoodRow extends StatelessWidget {
  final List<String> moods;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const MoodRow({
    super.key,
    required this.moods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < moods.length; i++) ...[
          Expanded(
            child: _MoodTile(
              label: moods[i],
              active: selected == moods[i],
              onTap: () => onChanged(selected == moods[i] ? null : moods[i]),
            ),
          ),
          if (i != moods.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MoodTile({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          decoration: BoxDecoration(
            color: active ? Tokens.ink : Tokens.bg,
            border: Border.all(
              color: active ? Tokens.ink : Tokens.borderSoft,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(Tokens.r1),
          ),
          child: Center(
            child: Text(
              displayCase(label),
              textAlign: TextAlign.center,
              style: Type.mono(
                size: 10,
                color: active ? Tokens.paper : Tokens.ink,
                letterSpacingEm: 0.02,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
