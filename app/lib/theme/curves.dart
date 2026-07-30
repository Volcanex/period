/// Easing functions shared by the app's hand-rolled animations.
///
/// These are plain functions rather than `Curve` subclasses because the
/// callers drive multi-phase keyframes by hand and need to evaluate a curve
/// at an arbitrary `t` partway through a controller, not hand a curve to an
/// implicit animation.
library;

class AppCurves {
  AppCurves._();

  static double easeOutCubic(double x) {
    final clamped = x.clamp(0.0, 1.0);
    final inv = 1 - clamped;
    return 1 - inv * inv * inv;
  }

  /// Overshoots past 1 before settling. `c1` is the standard tuning constant.
  static double easeOutBack(double x) {
    final clamped = x.clamp(0.0, 1.0);
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final p = clamped - 1;
    return 1 + c3 * p * p * p + c1 * p * p;
  }
}
