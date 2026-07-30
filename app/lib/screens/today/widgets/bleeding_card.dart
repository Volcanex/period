import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class BleedingCard extends StatelessWidget {
  final BleedLevel? value;
  final ValueChanged<BleedLevel> onChanged;

  const BleedingCard({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final logged = value != null && value != BleedLevel.none;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DropGlyph(color: Tokens.oxide, size: 10),
                  const SizedBox(width: 8),
                  Text(
                    'Bleeding',
                    style: Type.display(
                      size: 15,
                      weight: Tokens.fwMedium,
                      height: 1.2,
                      letterSpacingEm: -0.01,
                    ),
                  ),
                ],
              ),
              Text(
                logged ? value!.label.toUpperCase() : 'NOT LOGGED',
                style: Type.mono(
                  size: 10,
                  color: logged ? Tokens.oxide : Tokens.graphite2,
                  letterSpacingEm: 0.08,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Segmented(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final BleedLevel? value;
  final ValueChanged<BleedLevel> onChanged;
  const _Segmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.r1),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Tokens.borderSoft, width: 1),
          borderRadius: BorderRadius.circular(Tokens.r1),
        ),
        child: Row(
          children: [
            for (var i = 0; i < BleedLevel.values.length; i++)
              Expanded(
                child: _Step(
                  level: BleedLevel.values[i],
                  active: value == BleedLevel.values[i],
                  hasRightBorder: i != BleedLevel.values.length - 1,
                  onTap: () => onChanged(BleedLevel.values[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final BleedLevel level;
  final bool active;
  final bool hasRightBorder;
  final VoidCallback onTap;

  const _Step({
    required this.level,
    required this.active,
    required this.hasRightBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = active ? Tokens.ink : Colors.transparent;
    final color = active ? Tokens.paper : Tokens.graphite2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            color: activeBg,
            border: Border(
              right: hasRightBorder
                  ? BorderSide(color: Tokens.borderSoft, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _StepGlyph(level: level, active: active),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayCase(level.label),
                style: Type.mono(
                  size: 9.5,
                  color: color,
                  letterSpacingEm: 0.02,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepGlyph extends StatelessWidget {
  final BleedLevel level;
  final bool active;
  const _StepGlyph({required this.level, required this.active});

  @override
  Widget build(BuildContext context) {
    if (level == BleedLevel.none) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Tokens.paper : Tokens.graphite2,
            width: 1,
          ),
        ),
      );
    }
    final size = switch (level) {
      BleedLevel.spot => 4.0,
      BleedLevel.light => 8.0,
      BleedLevel.med => 12.0,
      BleedLevel.heavy => 14.0,
      _ => 0.0,
    };
    return _DropGlyph(color: Tokens.oxide, size: size);
  }
}

/// Teardrop: a circle with one corner squared.
/// In the design CSS this is `border-radius: 50% 50% 50% 0; transform: rotate(-45deg)`.
class _DropGlyph extends StatelessWidget {
  final Color color;
  final double size;
  const _DropGlyph({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398, // -45deg
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size / 2),
            topRight: Radius.circular(size / 2),
            bottomRight: Radius.circular(size / 2),
            bottomLeft: Radius.zero,
          ),
        ),
      ),
    );
  }
}
