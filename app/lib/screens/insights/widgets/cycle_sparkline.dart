import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Tiny line chart of recent cycle lengths. Dashed average line, ink stroke,
/// dots at each sample (last sample tinted oxide so the most recent reading
/// stands out).
class CycleSparkline extends StatelessWidget {
  final List<double> values;
  final double average;
  final double minV;
  final double maxV;

  const CycleSparkline({
    super.key,
    required this.values,
    required this.average,
    required this.minV,
    required this.maxV,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(
        values: values,
        average: average,
        minV: minV,
        maxV: maxV,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  static const _pad = 6.0;

  final List<double> values;
  final double average;
  final double minV;
  final double maxV;

  _SparklinePainter({
    required this.values,
    required this.average,
    required this.minV,
    required this.maxV,
  });

  double _yFor(double v, Size size) {
    final t = ((v - minV) / (maxV - minV)).clamp(0, 1).toDouble();
    return _pad + (1 - t) * (size.height - _pad * 2);
  }

  double _xFor(int i, Size size) {
    if (values.length == 1) return size.width / 2;
    return _pad + (i / (values.length - 1)) * (size.width - _pad * 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Average line — dashed.
    final avgY = _yFor(average, size);
    final dashPaint = Paint()
      ..color = Tokens.borderSoft
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 2.0;
    const gap = 3.0;
    var x = _pad;
    while (x < size.width - _pad) {
      canvas.drawLine(Offset(x, avgY), Offset(x + dash, avgY), dashPaint);
      x += dash + gap;
    }

    // Line through the values.
    final linePaint = Paint()
      ..color = Tokens.ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(_xFor(i, size), _yFor(values[i], size));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Dots.
    final dotInk = Paint()..color = Tokens.ink;
    final dotLast = Paint()..color = Tokens.phaseMenstrual;
    for (var i = 0; i < values.length; i++) {
      final p = Offset(_xFor(i, size), _yFor(values[i], size));
      final isLast = i == values.length - 1;
      canvas.drawCircle(p, 2.5, isLast ? dotLast : dotInk);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.average != average ||
      old.minV != minV ||
      old.maxV != maxV;
}
