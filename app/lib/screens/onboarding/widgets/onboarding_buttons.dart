import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// Shrinks slightly while held. Wraps any tappable so press feedback is
/// consistent without pulling in Material's ripple.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _held = false;

  void _set(bool v) {
    if (widget.onTap == null || _held == v) return;
    setState(() => _held = v);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _held ? 0.985 : 1.0,
          duration: Tokens.durFast,
          curve: Tokens.ease,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Full-width ink button. Matches `SheetPrimaryButton` visually but is
/// hand-rolled, so there is no ripple.
///
/// With [enabled] false it reads as "not yet" rather than broken: outlined and
/// muted, animating to filled the moment it becomes available.
class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final on = enabled && onPressed != null;
    return PressableScale(
      onTap: on ? onPressed : null,
      child: AnimatedContainer(
        duration: Tokens.durFast,
        curve: Tokens.ease,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: on ? Tokens.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(Tokens.r2),
          border: Border.all(
            color: on ? Tokens.ink : Tokens.borderSoft,
            width: Tokens.bwRule,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: Tokens.durFast,
          curve: Tokens.ease,
          style: Type.body(
            size: 14,
            weight: Tokens.fwMedium,
            color: on ? Tokens.paper : Tokens.graphite2,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Quiet secondary action — the skips, and `SKIP` on the tour.
class OnboardingTextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool mono;

  const OnboardingTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            mono ? label.toUpperCase() : label,
            textAlign: TextAlign.center,
            style: mono
                ? Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.08,
                    height: 1.0,
                  )
                : Type.body(size: 14, color: Tokens.graphite2, height: 1.0),
          ),
        ),
      ),
    );
  }
}
