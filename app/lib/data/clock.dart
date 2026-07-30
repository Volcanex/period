/// Single source of truth for "what day is it" and the demo cycle anchor.
///
/// Today is the device date (with time stripped). The cycle anchor is
/// derived from today so the demo always shows today as cycle day 4 — i.e.
/// late flow — preserving the visual narrative of the original handoff
/// (which hardcoded may 4 2026 as flow day 4) regardless of the user's
/// real calendar.
///
/// When `LocalStoreSnapshot` lands, `cycleAnchor` becomes "the most recent
/// logged period start," not a fixture. Today's day-of-week + month-name
/// are pure date math and don't change.
library;

class Clock {
  Clock._();

  /// Allow tests / dev tools to pin the clock. Defaults to `DateTime.now()`.
  static DateTime Function() _source = DateTime.now;

  /// Pin the clock to a specific date. Pass `null` to restore live time.
  /// For dev-tools and tests only.
  static void overrideNow(DateTime? d) {
    _source = d == null ? DateTime.now : () => d;
  }

  /// Today, with time stripped. Comparable by `==` to other Clock.today calls
  /// taken on the same calendar day.
  static DateTime get today {
    final now = _source();
    return DateTime(now.year, now.month, now.day);
  }

  /// Demo: cycle anchor sits 3 days before today, so today is cycle day 4.
  static DateTime? _cycleAnchorOverride;
  static int? _cycleLenOverride;
  static int? _flowLenOverride;
  static int? _ovPeakOverride;

  /// Set by the local app store once persisted state has loaded. Pass `null`
  /// to return to the first-run demo anchor.
  static void overrideCycleAnchor(DateTime? d) {
    _cycleAnchorOverride = d == null ? null : DateTime(d.year, d.month, d.day);
  }

  /// Assignment, not merge — every field is replaced, so a caller passing
  /// only `cycleLen:` also resets the anchor and the known-flag.
  static void overrideCycleConfig({
    DateTime? anchor,
    bool anchorKnown = true,
    int? cycleLen,
    int? flowLen,
    int? ovPeak,
  }) {
    overrideCycleAnchor(anchor);
    _cycleAnchorKnown = anchorKnown;
    _cycleLenOverride = cycleLen;
    _flowLenOverride = flowLen;
    _ovPeakOverride = ovPeak;
  }

  static bool _cycleAnchorKnown = true;

  /// False when nobody has told us when the last period started. Anything
  /// user-visible — a cycle day, a phase tint, a prediction — must check this
  /// first.
  static bool get hasCycleAnchor => _cycleAnchorKnown;

  /// The anchor, or null when it is genuinely unknown. Prefer this over
  /// [cycleAnchor] anywhere the result reaches the screen.
  static DateTime? get cycleAnchorOrNull =>
      _cycleAnchorKnown ? cycleAnchor : null;

  /// WARNING: this falls back to `today - 3` when nothing has been set, which
  /// is a fabricated date kept only so grid arithmetic has something to
  /// subtract. It is not a real anchor and must never reach the screen —
  /// gate on [hasCycleAnchor], or use [cycleAnchorOrNull]. Showing this value
  /// is the bug onboarding exists to fix.
  static DateTime get cycleAnchor =>
      _cycleAnchorOverride ?? today.subtract(const Duration(days: 3));

  /// Demo: 28-day reference cycle.
  static int get cycleLen => _cycleLenOverride ?? 28;

  /// Demo: 4-day flow.
  static int get flowLen => _flowLenOverride ?? 4;

  /// Demo: ovulation peak day.
  static int get ovPeak => _ovPeakOverride ?? 14;
}
