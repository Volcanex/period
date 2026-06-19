import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// Wraps a section in either a bordered card or a "bare" header-and-content
/// pair (no card). Mirrors `.sec` and `.sec.bare` in app.css.
class SectionBox extends StatelessWidget {
  final String eyebrow;
  final Widget? trailing;
  final Widget child;
  final bool bare;

  const SectionBox({
    super.key,
    required this.eyebrow,
    this.trailing,
    required this.child,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(eyebrow.toUpperCase(), style: Type.eyebrow()),
        ?trailing,
      ],
    );

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, const SizedBox(height: 10), child],
    );

    if (bare) return inner;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: inner,
    );
  }
}

/// Mono "edit" / "clear" / "tap to set severity" link in section heads.
class SectionAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool muted;

  const SectionAction({
    super.key,
    required this.label,
    this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Type.mono(
      size: 10,
      color: muted ? Tokens.graphite2 : Tokens.ink,
      letterSpacingEm: 0.08,
      height: 1.0,
    );
    final text = Text(
      label.toUpperCase(),
      style: muted
          ? style
          : style.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: Tokens.borderSoft,
            ),
    );
    if (onTap == null || muted) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: text),
    );
  }
}
