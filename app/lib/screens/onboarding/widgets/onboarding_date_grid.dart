import 'package:flutter/material.dart';

import '../../../theme/curves.dart';
import '../../../theme/layout.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../shared/month_nav.dart';
import '../../shared/weekday_header.dart';

const _monthNames = [
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

const _weekdayNames = [
  '',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Month grid for picking a past date.
///
/// Deliberately flatter than the calendar tab: at setup time there is no cycle
/// model, so there are no phase tints to show. Future days are inert rather
/// than erroring — there is nothing to explain, they just aren't answers to
/// "when did it start".
class OnboardingDateGrid extends StatefulWidget {
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final int monthsBack;

  const OnboardingDateGrid({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    this.monthsBack = 6,
  });

  @override
  State<OnboardingDateGrid> createState() => _OnboardingDateGridState();
}

class _OnboardingDateGridState extends State<OnboardingDateGrid> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  DateTime get _earliest =>
      DateTime(widget.today.year, widget.today.month - widget.monthsBack, 1);

  bool get _canGoBack => _month.isAfter(_earliest);
  bool get _canGoForward =>
      _month.isBefore(DateTime(widget.today.year, widget.today.month));

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    // Same cell cap as the calendar tab — a wider column gets wider margins,
    // not bigger days.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.monthGridMax),
        child: Column(
          children: [
            MonthNav(
              month: _month,
              onBack: _canGoBack ? () => _shift(-1) : null,
              onForward: _canGoForward ? () => _shift(1) : null,
            ),
            const SizedBox(height: 14),
            const WeekdayHeader(),
            const SizedBox(height: 6),
            _Grid(
              month: _month,
              today: widget.today,
              selected: widget.selected,
              onSelected: widget.onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const _Grid({
    required this.month,
    required this.today,
    required this.selected,
    required this.onSelected,
  });

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first, matching the calendar tab.
    final leadOffset = (DateTime(month.year, month.month, 1).weekday - 1) % 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final cell = (constraints.maxWidth - gap * 6) / 7;
        final children = <Widget>[];

        for (var i = 0; i < leadOffset; i++) {
          children.add(SizedBox(width: cell, height: cell));
        }
        for (var d = 1; d <= daysInMonth; d++) {
          final date = DateTime(month.year, month.month, d);
          final isFuture = date.isAfter(today);
          final isSelected = selected != null && _sameDay(date, selected!);
          children.add(
            SizedBox(
              width: cell,
              height: cell,
              child: _DateCell(
                date: date,
                isToday: _sameDay(date, today),
                isFuture: isFuture,
                isSelected: isSelected,
                onTap: isFuture ? null : () => onSelected(date),
              ),
            ),
          );
        }
        return Wrap(spacing: gap, runSpacing: gap, children: children);
      },
    );
  }
}

class _DateCell extends StatefulWidget {
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DateCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<_DateCell>
    with SingleTickerProviderStateMixin {
  // The one expressive moment in setup. A lift, deliberately without the
  // calendar's glow — that bloom is its signature and repeating it here would
  // spend it twice.
  static const _liftEnd = 0.444; // durFast / (durFast + durBase)

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: Tokens.durFast + Tokens.durBase,
  );

  @override
  void didUpdateWidget(covariant _DateCell old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _hop.value = 1;
      } else {
        _hop.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label =
        '${_weekdayNames[widget.date.weekday]}, '
        '${_monthNames[widget.date.month]} ${widget.date.day}';

    return Semantics(
      button: !widget.isFuture,
      enabled: !widget.isFuture,
      selected: widget.isSelected,
      label: label,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _hop,
            child: _body(),
            builder: (context, child) {
              final t = _hop.value;
              final double lift;
              final double scale;
              if (t <= _liftEnd) {
                final p = AppCurves.easeOutBack(t / _liftEnd);
                lift = -4.0 * p;
                scale = 1 + 0.06 * p;
              } else {
                final p = AppCurves.easeOutCubic(
                  (t - _liftEnd) / (1 - _liftEnd),
                );
                lift = -4.0 + 4.0 * p;
                scale = 1.06 - 0.06 * p;
              }
              return Transform.translate(
                offset: Offset(0, lift),
                child: Transform.scale(scale: scale, child: child),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final Color fill;
    final Color border;
    final Color fg;

    if (widget.isSelected) {
      // Solid oxide — the same treatment a logged flow day gets in the
      // calendar, because that is what this day is about to become.
      fill = Tokens.phaseMenstrual;
      border = Tokens.phaseMenstrual;
      fg = const Color(0xFFFFFFFF);
    } else if (widget.isFuture) {
      fill = Colors.transparent;
      border = Tokens.borderSoft.withValues(alpha: 0.4);
      fg = Tokens.graphite2.withValues(alpha: 0.45);
    } else if (widget.isToday) {
      fill = Tokens.bg;
      border = Tokens.ink.withValues(alpha: 0.35);
      fg = Tokens.ink;
    } else {
      fill = Tokens.bg;
      border = Tokens.graphite.withValues(alpha: 0.18);
      fg = Tokens.ink;
    }

    return AnimatedContainer(
      duration: Tokens.durFast,
      curve: Tokens.ease,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Tokens.r1),
        border: Border.all(
          color: border,
          width: widget.isSelected ? Tokens.bwRule : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${widget.date.day}',
        style: Type.display(
          size: 13,
          color: fg,
          height: 1.0,
          letterSpacingEm: 0.0,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
