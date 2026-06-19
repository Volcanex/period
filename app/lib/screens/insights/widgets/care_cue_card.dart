import 'package:flutter/material.dart';

import '../insight_prompt.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

/// A detector-shaped insight card: careful language, evidence summary,
/// primary next step, and dismiss. These are care cues, not diagnoses.
class CareCueCard extends StatelessWidget {
  final CareCueKind kind;
  final String eyebrow;
  final String title;
  final String body;
  final String evidenceSummary;
  final CareCueAction action;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const CareCueCard({
    super.key,
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.evidenceSummary,
    required this.action,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg = kind == CareCueKind.supportPack
        ? Tokens.phaseCalLuteal
        : Tokens.sky1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Stack(
        children: [
          // Reserve room for the dismiss button on the right.
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CareCueGlyph(kind: kind),
                    const SizedBox(width: 6),
                    Text(eyebrow.toUpperCase(), style: Type.eyebrow(size: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: Type.display(
                    size: 16,
                    weight: Tokens.fwMedium,
                    height: 1.3,
                    letterSpacingEm: -0.01,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: Type.body(size: 13, height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        evidenceSummary,
                        style: Type.mono(
                          size: 10,
                          color: Tokens.graphite2,
                          letterSpacingEm: 0.04,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (action.kind != CareCueActionKind.none)
                      _ActionButton(label: action.label, onPressed: onAction),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Tokens.graphite2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareCueGlyph extends StatelessWidget {
  final CareCueKind kind;

  const _CareCueGlyph({required this.kind});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11,
      height: 11,
      child: CustomPaint(painter: _CareCueGlyphPainter(kind)),
    );
  }
}

class _CareCueGlyphPainter extends CustomPainter {
  final CareCueKind kind;

  const _CareCueGlyphPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Tokens.graphite2
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (kind == CareCueKind.supportPack) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.drawLine(Offset(cx, 0.8), Offset(cx, size.height - 0.8), paint);
      canvas.drawLine(Offset(0.8, cy), Offset(size.width - 0.8, cy), paint);
      canvas.drawLine(
        const Offset(2.4, 2.4),
        Offset(size.width - 2.4, size.height - 2.4),
        paint,
      );
      canvas.drawLine(
        Offset(size.width - 2.4, 2.4),
        Offset(2.4, size.height - 2.4),
        paint,
      );
      return;
    }

    final path = Path()
      ..moveTo(1, size.height - 2)
      ..lineTo(size.width * 0.38, size.height * 0.58)
      ..lineTo(size.width * 0.62, size.height * 0.70)
      ..lineTo(size.width - 1, 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CareCueGlyphPainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Tokens.ink,
            borderRadius: BorderRadius.circular(Tokens.r1),
          ),
          child: Text(
            '$label →',
            style: Type.mono(
              size: 11,
              color: Tokens.paper,
              letterSpacingEm: 0.02,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
