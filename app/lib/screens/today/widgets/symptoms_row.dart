import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class SymptomsRow extends StatelessWidget {
  final List<String> symptoms;
  final Map<String, Severity> values;
  final void Function(String symptom) onTapSymptom;
  final VoidCallback onTapMore;

  const SymptomsRow({
    super.key,
    required this.symptoms,
    required this.values,
    required this.onTapSymptom,
    required this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in symptoms)
          _SymChip(
            label: s,
            severity: values[s],
            onTap: () => onTapSymptom(s),
          ),
        _MoreChip(onTap: onTapMore),
      ],
    );
  }
}

class _SymChip extends StatelessWidget {
  final String label;
  final Severity? severity;
  final VoidCallback onTap;

  const _SymChip({required this.label, required this.severity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final set = severity != null;
    final bgColor = set ? Tokens.ink : Tokens.bg;
    final textColor = set ? Tokens.paper : Tokens.ink;
    final borderColor = set ? Tokens.ink : Tokens.borderSoft;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(Tokens.r1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SevDot(severity: severity, set: set),
              const SizedBox(width: 6),
              Text(
                label,
                style: Type.mono(
                  size: 11,
                  color: textColor,
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

class _SevDot extends StatelessWidget {
  final Severity? severity;
  final bool set;
  const _SevDot({required this.severity, required this.set});

  @override
  Widget build(BuildContext context) {
    Color borderColor = Tokens.graphite;
    Color? fillColor;
    double fillOpacity = 1.0;

    if (!set) {
      // Outline only on default state.
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Tokens.graphite, width: 1),
        ),
      );
    }

    borderColor = Tokens.paper;
    switch (severity!) {
      case Severity.mild:
        fillColor = Tokens.paper;
        fillOpacity = 0.4;
        break;
      case Severity.moderate:
        fillColor = Tokens.paper;
        fillOpacity = 0.7;
        break;
      case Severity.severe:
        fillColor = Tokens.oxide;
        borderColor = Tokens.oxide;
        fillOpacity = 1.0;
        break;
    }

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor.withValues(alpha: fillOpacity),
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DottedBorderBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              '+ more',
              style: Type.mono(
                size: 11,
                color: Tokens.graphite2,
                letterSpacingEm: 0.02,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faux dashed border using DecoratedBox is awkward in Flutter; we use a
/// simple solid soft border at the right opacity to read as "ghost".
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.borderSoft, width: 1, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(Tokens.r1),
      ),
      child: child,
    );
  }
}
