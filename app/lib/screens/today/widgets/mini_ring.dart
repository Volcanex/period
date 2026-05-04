import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Compact cycle ring: four phase arcs at light tints, a stronger flow arc on
/// top, an ovulation peak marker, and a today dot.
///
/// Direct port of `MiniRing` from the design's `components.jsx` (lines 60-117).
class MiniRing extends StatelessWidget {
  final int day;
  final int cycleLen;
  final int flowLen;
  final double size;

  const MiniRing({
    super.key,
    this.day = 12,
    this.cycleLen = 28,
    this.flowLen = 5,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniRingPainter(
          day: day,
          cycleLen: cycleLen,
          flowLen: flowLen,
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final int day;
  final int cycleLen;
  final int flowLen;

  _MiniRingPainter({
    required this.day,
    required this.cycleLen,
    required this.flowLen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = math.max(4.0, (size.width / 12).round().toDouble());
    final r = size.width / 2 - sw / 2 - 2;
    final mid = (cycleLen / 2).round();

    final phases = <_Phase>[
      _Phase(1, flowLen + 1, Tokens.phaseMenstrualSoft),
      _Phase(flowLen + 1, mid - 1, Tokens.phaseFollicular),
      _Phase(mid - 1, mid + 2, Tokens.phaseOvulation),
      _Phase(mid + 2, cycleLen + 1, Tokens.phaseLuteal),
    ];

    for (final p in phases) {
      _drawArc(canvas, cx, cy, r, sw, p.from, p.to, p.color);
    }

    // Stronger flow arc on top of the menstrual band.
    _drawArc(canvas, cx, cy, r, sw, 1, flowLen + 1, Tokens.phaseMenstrual);

    // Ovulation peak marker — dashed circle at mid - 0.5.
    final ovFrac = (mid - 0.5) / cycleLen;
    final ovAng = -math.pi / 2 + ovFrac * 2 * math.pi;
    final ovX = cx + r * math.cos(ovAng);
    final ovY = cy + r * math.sin(ovAng);
    _drawDashedCircle(
      canvas,
      Offset(ovX, ovY),
      math.max(2.0, sw * 0.45),
      Tokens.phaseOvulationDeep,
      strokeWidth: 1.5,
      dashOn: 1.5,
      dashOff: 1.5,
    );

    // Today dot.
    final dayFrac = day / cycleLen;
    final ang = -math.pi / 2 + dayFrac * 2 * math.pi;
    final dotX = cx + r * math.cos(ang);
    final dotY = cy + r * math.sin(ang);
    final dotR = math.max(3.5, sw * 0.7);
    final dotStroke = Paint()
      ..color = Tokens.base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dotFill = Paint()..color = Tokens.ink;
    canvas.drawCircle(Offset(dotX, dotY), dotR, dotStroke);
    canvas.drawCircle(Offset(dotX, dotY), dotR, dotFill);
  }

  void _drawArc(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
    int fromDay,
    int toDay,
    Color color,
  ) {
    final fStart = (fromDay - 1) / cycleLen;
    final fEnd = (toDay - 1) / cycleLen;
    final len = math.max(0.0, fEnd - fStart);
    if (len <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;
    final start = -math.pi / 2 + fStart * 2 * math.pi;
    final sweep = len * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false, paint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    required double strokeWidth,
    required double dashOn,
    required double dashOff,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashOn + dashOff)).round();
    final stepRad = 2 * math.pi / dashCount;
    final onRad = stepRad * (dashOn / (dashOn + dashOff));
    for (var i = 0; i < dashCount; i++) {
      final start = i * stepRad;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        onRad,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter oldDelegate) =>
      oldDelegate.day != day ||
      oldDelegate.cycleLen != cycleLen ||
      oldDelegate.flowLen != flowLen;
}

class _Phase {
  final int from;
  final int to;
  final Color color;
  _Phase(this.from, this.to, this.color);
}
