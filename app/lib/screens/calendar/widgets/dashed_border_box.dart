import 'package:flutter/material.dart';

/// A rounded-rect dashed border drawn around a child. Flutter's
/// BoxDecoration doesn't support dashed borders natively, so we paint
/// the rect by walking its perimeter.
class DashedBorderBox extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashOn;
  final double dashOff;
  final Widget child;

  const DashedBorderBox({
    super.key,
    required this.color,
    required this.strokeWidth,
    required this.radius,
    this.dashOn = 3,
    this.dashOff = 2,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dashOn: dashOn,
        dashOff: dashOff,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashOn;
  final double dashOff;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashOn,
    required this.dashOff,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - 2 * inset,
        size.height - 2 * inset,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = (dist + dashOn).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + dashOff;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashOn != dashOn ||
      old.dashOff != dashOff;
}
