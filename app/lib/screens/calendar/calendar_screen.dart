import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/contracts/tracker_definition.dart';
import '../../data/clock.dart';
import '../../data/models.dart';
import '../../state/local_period_store.dart';
import '../../theme/curves.dart';
import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import '../shared/month_nav.dart';
import '../shared/weekday_header.dart';
import '../today/widgets/mini_ring.dart';
import 'sheets/day_sheet.dart';
import 'widgets/dashed_border_box.dart';

/// Calendar tab — month grid with phase tints, today marker, and a legend.
/// Direct port of `CalendarScreenStub` in `other-tabs.jsx` (lines 26-160),
/// extended with month paging and per-day tap-to-view.
///
/// Phase math is anchored on the demo cycle (cycleAnchor = may 1 2026,
/// cycleLen = 28, flowLen = 4) and projected forward/backward by simple
/// modular arithmetic. When real cycle data lands this becomes a lookup
/// against `LocalStoreSnapshot`.
class CalendarScreen extends StatefulWidget {
  final DayLog Function(DateTime date) logFor;
  final List<TrackerDefinition> activeDefinitions;
  final void Function(DateTime date, BleedLevel level) onBleedingChanged;
  final void Function(
    DateTime date,
    String symptom,
    Severity? severity,
    String note,
  )
  onSymptomChanged;
  final void Function(DateTime date, String? mood) onMoodChanged;
  final void Function(DateTime date, String trackerId, double? value)
  onNumericChanged;
  final void Function(DateTime date, String trackerCode, String? value)
  onEnumChanged;
  final void Function(DateTime date, String trackerCode, bool? value)
  onBooleanChanged;
  final void Function(DateTime date, String trackerCode, String value)
  onTextChanged;
  final void Function(DateTime date, String note) onNoteChanged;

  const CalendarScreen({
    super.key,
    required this.logFor,
    required this.activeDefinitions,
    required this.onBleedingChanged,
    required this.onSymptomChanged,
    required this.onMoodChanged,
    required this.onNumericChanged,
    required this.onEnumChanged,
    required this.onBooleanChanged,
    required this.onTextChanged,
    required this.onNoteChanged,
  });

  // Cycle math flows through `Clock` so the calendar tracks the device date
  // and, crucially, the user's configured cycle length. The ovulation window
  // brackets the peak day (which `Clock`/the store scale with cycle length)
  // rather than being pinned to a 28-day reference.
  static DateTime get today => Clock.today;
  static DateTime get cycleAnchor => Clock.cycleAnchor;
  static bool get hasCycleAnchor => Clock.hasCycleAnchor;
  static int get cycleLen => Clock.cycleLen;
  static int get flowLen => Clock.flowLen;
  static int get ovPeak => Clock.ovPeak;
  static int get ovStart => (ovPeak - 1).clamp(1, cycleLen);
  static int get ovEnd => (ovPeak + 1).clamp(1, cycleLen);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final t = CalendarScreen.today;
    _visibleMonth = DateTime(t.year, t.month);
  }

  void _stepMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Future<void> _openDay(DateTime date, _Phase? phase, _Kind kind) async {
    final today = CalendarScreen.today;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isFuture = dateOnly.isAfter(todayOnly);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DaySheet(
        date: date,
        phaseLabel: _phaseLabel(phase),
        kindLabel: _kindLabel(kind),
        cycleDay: _cycleDayFor(date),
        log: widget.logFor(date),
        activeDefinitions: widget.activeDefinitions,
        isToday: _sameDay(date, CalendarScreen.today),
        isFuture: isFuture,
        onBleedingChanged: (level) => widget.onBleedingChanged(date, level),
        onSymptomChanged: (symptom, severity, note) =>
            widget.onSymptomChanged(date, symptom, severity, note),
        onMoodChanged: (mood) => widget.onMoodChanged(date, mood),
        onNumericChanged: (id, value) =>
            widget.onNumericChanged(date, id, value),
        onEnumChanged: (id, value) => widget.onEnumChanged(date, id, value),
        onBooleanChanged: (id, value) =>
            widget.onBooleanChanged(date, id, value),
        onTextChanged: (id, value) => widget.onTextChanged(date, id, value),
        onNoteChanged: (note) => widget.onNoteChanged(date, note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Calendar'),
        Expanded(
          child: Container(
            color: Tokens.base,
            child: ContentPane(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                children: [
                  const _CycleOverview(),
                  const SizedBox(height: 18),
                  // Header and grid share one cap so the columns stay aligned
                  // and the cells stop growing on a desktop window.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Layout.monthGridMax,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MonthNav(
                            month: _visibleMonth,
                            onBack: () => _stepMonth(-1),
                            onForward: () => _stepMonth(1),
                          ),
                          const SizedBox(height: 14),
                          const WeekdayHeader(),
                          const SizedBox(height: 6),
                          _MonthGrid(
                            monthAnchor: _visibleMonth,
                            logFor: widget.logFor,
                            onTapDay: _openDay,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _Legend(),
                  const SizedBox(height: 12),
                  const _FooterHint(),
                  SizedBox(
                    height: Layout.of(context) == Breakpoint.compact ? 80 : 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _phaseLabel(_Phase? p) => switch (p) {
    null => '',
    _Phase.menstrual => 'Menstrual',
    _Phase.follicular => 'Follicular',
    _Phase.ovulation => 'Ovulation',
    _Phase.luteal => 'Luteal',
  };

  static String _kindLabel(_Kind k) => switch (k) {
    _Kind.none => '',
    _Kind.today => 'Today',
    _Kind.ovulationPeak => 'Ovulation peak (estimated)',
    _Kind.flowPast => 'Logged flow',
    _Kind.flowPredicted => 'Predicted flow',
  };

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---- pure phase math, exposed so DaySheet + grid agree ----

/// Null when no period start is known — there is no cycle to be on a day of.
int? _cycleDayFor(DateTime d) {
  if (!CalendarScreen.hasCycleAnchor) return null;
  final diff = d.difference(CalendarScreen.cycleAnchor).inDays;
  final m = diff % CalendarScreen.cycleLen;
  final mod = m < 0 ? m + CalendarScreen.cycleLen : m;
  return mod + 1; // 1-based
}

_Phase? _phaseFor(int? cycleDay) {
  if (cycleDay == null) return null;
  if (cycleDay <= CalendarScreen.flowLen) return _Phase.menstrual;
  if (cycleDay >= CalendarScreen.ovStart && cycleDay <= CalendarScreen.ovEnd) {
    return _Phase.ovulation;
  }
  if (cycleDay < CalendarScreen.ovStart) return _Phase.follicular;
  return _Phase.luteal; // post-ovulation through to the next flow
}

// ---- cycle overview ----

String _ovulationWindowText() {
  const names = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final start = CalendarScreen.cycleAnchor.add(
    Duration(days: CalendarScreen.ovStart - 1),
  );
  final end = CalendarScreen.cycleAnchor.add(
    Duration(days: CalendarScreen.ovEnd - 1),
  );
  // Same month: "may 13–15". Different months: "apr 30–may 2".
  if (start.month == end.month) {
    return '${names[start.month]} ${start.day}–${end.day}';
  }
  return '${names[start.month]} ${start.day}–${names[end.month]} ${end.day}';
}

class _CycleOverview extends StatelessWidget {
  const _CycleOverview();

  @override
  Widget build(BuildContext context) {
    final cd = _cycleDayFor(CalendarScreen.today);
    if (cd == null) return const _CycleOverviewUnknown();

    final phase = _phaseFor(cd);
    final phaseStr = _CalendarScreenState._phaseLabel(phase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniRing(
            day: cd,
            cycleLen: CalendarScreen.cycleLen,
            flowLen: CalendarScreen.flowLen,
            size: 84,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THIS CYCLE', style: Type.eyebrow()),
                const SizedBox(height: 4),
                Text(
                  '$phaseStr phase',
                  style: Type.display(
                    size: 18,
                    weight: Tokens.fwMedium,
                    height: 1.15,
                    letterSpacingEm: -0.01,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Day $cd \u00b7 ovulation est. ',
                        style: Type.mono(
                          size: 11,
                          color: Tokens.graphite2,
                          letterSpacingEm: 0.02,
                          height: 1.4,
                        ),
                      ),
                      TextSpan(
                        text: _ovulationWindowText(),
                        style: Type.mono(
                          size: 11,
                          color: Tokens.ink,
                          letterSpacingEm: 0.02,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// No period start is known, so there is no ring, no phase and no ovulation
/// estimate to draw. Says so rather than showing a cycle that was made up.
class _CycleOverviewUnknown extends StatelessWidget {
  const _CycleOverviewUnknown();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS CYCLE', style: Type.eyebrow()),
          const SizedBox(height: 4),
          Text(
            'No cycle data yet',
            style: Type.display(
              size: 18,
              weight: Tokens.fwMedium,
              height: 1.15,
              letterSpacingEm: -0.01,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a day you bled to start the model.',
            style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---- grid ----

enum _Phase { menstrual, follicular, ovulation, luteal }

enum _Kind { none, today, ovulationPeak, flowPast, flowPredicted }

class _Cell {
  final int n;
  final DateTime? date; // null for muted lead-in / trail
  final bool muted;
  final _Phase? phase;
  final _Kind kind;
  final bool logged;
  const _Cell({
    required this.n,
    this.date,
    this.muted = false,
    this.phase,
    this.kind = _Kind.none,
    this.logged = false,
  });
}

class _MonthGrid extends StatelessWidget {
  final DateTime monthAnchor; // first day of the visible month
  final DayLog Function(DateTime date) logFor;
  final void Function(DateTime, _Phase?, _Kind) onTapDay;

  const _MonthGrid({
    required this.monthAnchor,
    required this.logFor,
    required this.onTapDay,
  });

  List<_Cell> _buildCells() {
    final firstOfMonth = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      monthAnchor.year,
      monthAnchor.month,
    );
    // Mon=1..Sun=7 -> we want offset where Mon -> 0.
    final leadOffset = (firstOfMonth.weekday - 1) % 7;
    final cells = <_Cell>[];
    // Lead-in cells from previous month (muted).
    final prevMonth = DateTime(monthAnchor.year, monthAnchor.month, 0);
    final prevDays = prevMonth.day;
    for (var i = 0; i < leadOffset; i++) {
      final n = prevDays - leadOffset + 1 + i;
      cells.add(_Cell(n: n, muted: true));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(monthAnchor.year, monthAnchor.month, d);
      final cd = _cycleDayFor(date);
      final phase = _phaseFor(cd);
      final log = logFor(date);
      final isFuture = date.isAfter(CalendarScreen.today);
      _Kind kind = _Kind.none;
      if (log.hasFlow) {
        // A real logged day. Always shown, anchor or not.
        kind = _Kind.flowPast;
      } else if (cd == null) {
        // Nothing is predicted without an anchor, so no dashed estimate days
        // and no ovulation marker — only what was actually logged.
        kind = _Kind.none;
      } else if (cd <= CalendarScreen.flowLen && isFuture) {
        kind = _Kind.flowPredicted;
      } else if (phase == _Phase.ovulation && cd == CalendarScreen.ovPeak) {
        kind = _Kind.ovulationPeak;
      } else if (phase == _Phase.menstrual && isFuture) {
        kind = _Kind.flowPredicted;
      }
      if (_CalendarScreenState._sameDay(date, CalendarScreen.today)) {
        kind = _Kind.today;
      }
      cells.add(
        _Cell(
          n: d,
          date: date,
          phase: phase,
          kind: kind,
          logged: log.hasAnyLog,
        ),
      );
    }
    // Pad trailing to a multiple of 7 (so the grid stays full-width).
    while (cells.length % 7 != 0) {
      cells.add(
        _Cell(n: cells.length - leadOffset - daysInMonth + 1, muted: true),
      );
    }
    return cells;
  }

  Color _bgFor(_Cell c) {
    if (c.muted) return Colors.transparent;
    final isFlowSolid =
        c.kind == _Kind.flowPast ||
        c.kind == _Kind.flowPredicted ||
        (c.kind == _Kind.today && c.phase == _Phase.menstrual);
    if (isFlowSolid) return Tokens.phaseMenstrual;
    return switch (c.phase) {
      _Phase.menstrual => Tokens.phaseCalMenstrual,
      _Phase.follicular => Tokens.phaseCalFollicular,
      _Phase.ovulation => Tokens.phaseCalOvulation,
      _Phase.luteal => Tokens.phaseCalLuteal,
      null => Tokens.bg,
    };
  }

  Color _fgFor(_Cell c) {
    if (c.muted) return Tokens.graphite2;
    final isFlowSolid =
        c.kind == _Kind.flowPast ||
        c.kind == _Kind.flowPredicted ||
        (c.kind == _Kind.today && c.phase == _Phase.menstrual);
    return isFlowSolid ? const Color(0xFFFFFFFF) : Tokens.ink;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCells();
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 7;
        const gap = 4.0;
        final cellSize = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in cells)
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: _DayCell(
                  cell: c,
                  bg: _bgFor(c),
                  fg: _fgFor(c),
                  onTap: c.muted || c.date == null
                      ? null
                      : () => onTapDay(c.date!, c.phase, c.kind),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatefulWidget {
  final _Cell cell;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  const _DayCell({
    required this.cell,
    required this.bg,
    required this.fg,
    this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _todayPop;
  Timer? _todayPopDelay;

  bool get _isToday => widget.cell.kind == _Kind.today;

  @override
  void initState() {
    super.initState();
    _todayPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (_isToday) _startTodayPopAfterDelay();
  }

  @override
  void didUpdateWidget(covariant _DayCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasToday = oldWidget.cell.kind == _Kind.today;
    if (!wasToday && _isToday) {
      _todayPop.reset();
      _startTodayPopAfterDelay();
    }
  }

  @override
  void dispose() {
    _todayPopDelay?.cancel();
    _todayPop.dispose();
    super.dispose();
  }

  void _startTodayPopAfterDelay() {
    _todayPopDelay?.cancel();
    _todayPopDelay = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || !_isToday) return;
      _todayPop.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontWeight = widget.cell.kind == _Kind.today
        ? Tokens.fwSemibold
        : Tokens.fwMedium;
    final number = Text(
      '${widget.cell.n}',
      style: Type.display(
        size: 13,
        weight: fontWeight,
        color: widget.fg,
        height: 1.0,
        letterSpacingEm: 0.0,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );

    final isToday = widget.cell.kind == _Kind.today;
    final dashed = _isDashed(widget.cell);
    final borderColor = _borderColorFor(widget.cell);
    final width = _borderWidthFor(widget.cell);
    final todayGlowColor = isToday ? _todayGlowFor(widget.cell) : null;

    // Single container handles fill + border + radius. Avoids the corner
    // mismatch we saw when fill and border lived on different boxes with
    // independently rounded corners.
    Widget body = Container(
      decoration: BoxDecoration(
        color: isToday ? _todayFillFor(widget.cell) : widget.bg,
        borderRadius: BorderRadius.circular(Tokens.r1),
        border: dashed || isToday
            ? null
            : Border.all(color: borderColor, width: width),
      ),
      alignment: Alignment.center,
      child: number,
    );

    if (isToday) {
      // Today does one cute hop when the calendar opens, then settles flush.
      // A neutral shadow gives it weight; the phase-specific warm haze blooms
      // around and over the cell so it reads as color bloom instead of a
      // border.
      body = AnimatedBuilder(
        animation: _todayPop,
        child: body,
        builder: (context, child) {
          final m = _TodayMotion.at(_todayPop.value);
          return Transform.translate(
            offset: Offset(0, m.y),
            child: Transform.scale(
              scale: m.scale,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: Transform.scale(
                      scale: m.glowScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: todayGlowColor!.withValues(
                            alpha: Tokens.dark
                                ? m.glowFillAlphaDark
                                : m.glowFillAlphaLight,
                          ),
                          borderRadius: BorderRadius.circular(Tokens.r1),
                          boxShadow: [
                            BoxShadow(
                              color: todayGlowColor.withValues(
                                alpha: Tokens.dark
                                    ? m.glowAlphaDark
                                    : m.glowAlphaLight,
                              ),
                              blurRadius: m.glowBlur,
                              spreadRadius: m.glowSpread,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Tokens.r1),
                      boxShadow: [
                        BoxShadow(
                          color: Tokens.ink.withValues(
                            alpha: Tokens.dark
                                ? m.shadowAlphaDark
                                : m.shadowAlphaLight,
                          ),
                          blurRadius: m.shadowBlur,
                          offset: Offset(0, m.shadowOffset),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        child!,
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Tokens.r1),
                                gradient: RadialGradient(
                                  center: const Alignment(-0.25, -0.35),
                                  radius: 1.05,
                                  colors: [
                                    todayGlowColor.withValues(
                                      alpha: Tokens.dark
                                          ? m.washAlphaDark
                                          : m.washAlphaLight,
                                    ),
                                    todayGlowColor.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (dashed) {
      body = DashedBorderBox(
        color: borderColor,
        strokeWidth: width,
        radius: Tokens.r1,
        child: body,
      );
    }

    if (widget.onTap == null) return body;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: body,
      ),
    );
  }

  static Color _borderColorFor(_Cell c) {
    if (c.kind == _Kind.today) return Tokens.ink;
    if (c.kind == _Kind.flowPast) return Tokens.phaseMenstrual;
    if (c.kind == _Kind.flowPredicted) return const Color(0xFFFFFFFF);
    if (c.kind == _Kind.ovulationPeak) return Tokens.phaseOvulationDeep;
    if (c.muted) return Tokens.borderSoft;
    if (c.phase == _Phase.follicular) return Tokens.phaseFollicularEdge;
    return Tokens.graphite.withValues(alpha: 0.18);
  }

  static double _borderWidthFor(_Cell c) {
    return switch (c.kind) {
      _Kind.today => 2.0,
      _Kind.flowPredicted => 1.5,
      _Kind.ovulationPeak => 1.5,
      _ => 1.0,
    };
  }

  static bool _isDashed(_Cell c) =>
      c.kind == _Kind.flowPredicted || c.kind == _Kind.ovulationPeak;
}

class _TodayMotion {
  final double y;
  final double scale;
  final double glowScale;
  final double glowBlur;
  final double glowSpread;
  final double glowAlphaLight;
  final double glowAlphaDark;
  final double glowFillAlphaLight;
  final double glowFillAlphaDark;
  final double washAlphaLight;
  final double washAlphaDark;
  final double shadowBlur;
  final double shadowOffset;
  final double shadowAlphaLight;
  final double shadowAlphaDark;

  const _TodayMotion({
    required this.y,
    required this.scale,
    required this.glowScale,
    required this.glowBlur,
    required this.glowSpread,
    required this.glowAlphaLight,
    required this.glowAlphaDark,
    required this.glowFillAlphaLight,
    required this.glowFillAlphaDark,
    required this.washAlphaLight,
    required this.washAlphaDark,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.shadowAlphaLight,
    required this.shadowAlphaDark,
  });

  factory _TodayMotion.at(double t) {
    const liftEnd = 0.34;
    if (t <= liftEnd) {
      final p = AppCurves.easeOutBack(t / liftEnd);
      return _TodayMotion(
        y: -8.5 * p,
        scale: 1 + 0.05 * p,
        glowScale: 1.08 + 0.22 * p,
        glowBlur: 9 + 16 * p,
        glowSpread: 0.5 + 3.5 * p,
        glowAlphaLight: 0.12 + 0.12 * p,
        glowAlphaDark: 0.18 + 0.13 * p,
        glowFillAlphaLight: 0.06 + 0.07 * p,
        glowFillAlphaDark: 0.08 + 0.08 * p,
        washAlphaLight: 0.08 + 0.08 * p,
        washAlphaDark: 0.10 + 0.08 * p,
        shadowBlur: 3 + 5 * p,
        shadowOffset: 1 + 4 * p,
        shadowAlphaLight: 0.12 + 0.08 * p,
        shadowAlphaDark: 0.20 + 0.10 * p,
      );
    }

    final p = AppCurves.easeOutCubic((t - liftEnd) / (1 - liftEnd));
    return _TodayMotion(
      y: -8.5 + 8.5 * p,
      scale: 1.05 - 0.05 * p,
      glowScale: 1.30 - 0.12 * p,
      glowBlur: 25 - 8 * p,
      glowSpread: 4 - 1.8 * p,
      glowAlphaLight: 0.24 - 0.04 * p,
      glowAlphaDark: 0.31 - 0.05 * p,
      glowFillAlphaLight: 0.13 - 0.03 * p,
      glowFillAlphaDark: 0.16 - 0.04 * p,
      washAlphaLight: 0.16 - 0.04 * p,
      washAlphaDark: 0.18 - 0.04 * p,
      shadowBlur: 8 - 5 * p,
      shadowOffset: 5 - 5 * p,
      shadowAlphaLight: 0.20 - 0.10 * p,
      shadowAlphaDark: 0.30 - 0.14 * p,
    );
  }
}

Color _todayGlowFor(_Cell c) {
  return switch (c.phase) {
    _Phase.menstrual => Tokens.phaseCalMenstrualGlow,
    _Phase.follicular => Tokens.phaseCalFollicularGlow,
    _Phase.ovulation => Tokens.phaseCalOvulationGlow,
    _Phase.luteal => Tokens.phaseCalLutealGlow,
    null => Tokens.phaseCalFollicularGlow,
  };
}

Color _todayFillFor(_Cell c) {
  return switch (c.phase) {
    _Phase.menstrual => Tokens.phaseCalMenstrualToday,
    _Phase.follicular => Tokens.phaseCalFollicularToday,
    _Phase.ovulation => Tokens.phaseCalOvulationToday,
    _Phase.luteal => Tokens.phaseCalLutealToday,
    null => Tokens.phaseCalFollicularToday,
  };
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    // With no anchor the grid has no phase tints at all, so a key to them
    // would explain colours that aren't on screen.
    if (!CalendarScreen.hasCycleAnchor) return const SizedBox.shrink();

    final entries = <_LegendEntry>[
      const _LegendEntry(
        'Menstrual',
        Tokens.phaseMenstrual,
        Tokens.phaseMenstrual,
        false,
      ),
      _LegendEntry(
        'Follicular',
        Tokens.phaseCalFollicular,
        Tokens.phaseFollicularEdge,
        false,
      ),
      _LegendEntry(
        'Ovulation',
        Tokens.phaseCalOvulation,
        Tokens.phaseOvulationDeep,
        true,
      ),
      _LegendEntry(
        'Luteal',
        Tokens.phaseCalLuteal,
        Tokens.phaseLutealDeep,
        false,
      ),
      // Nothing on the grid is predicted without an anchor, so the key for it
      // would point at something that isn't there.
      if (CalendarScreen.hasCycleAnchor)
        const _LegendEntry(
          'Predicted',
          Colors.transparent,
          Tokens.phaseMenstrual,
          true,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PHASES', style: Type.eyebrow()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final e in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.dashed)
                    DashedBorderBox(
                      color: e.borderColor,
                      strokeWidth: 1,
                      radius: Tokens.r1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: e.bgColor,
                          borderRadius: BorderRadius.circular(Tokens.r1),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.bgColor,
                        borderRadius: BorderRadius.circular(Tokens.r1),
                        border: Border.all(color: e.borderColor, width: 1),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    e.label,
                    style: Type.body(size: 12, height: 1.0, color: Tokens.ink),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendEntry {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final bool dashed;
  const _LegendEntry(this.label, this.bgColor, this.borderColor, this.dashed);
}

class _FooterHint extends StatelessWidget {
  const _FooterHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '[ TAP A DAY TO VIEW OR LOG ]',
        style: Type.mono(
          size: 11,
          color: Tokens.graphite2,
          letterSpacingEm: 0.06,
          height: 1.0,
        ),
      ),
    );
  }
}
