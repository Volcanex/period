import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class RecentPattern extends StatelessWidget {
  final CycleState state;
  const RecentPattern({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT PATTERN', style: Type.eyebrow()),
          const SizedBox(height: 10),
          if (state.avg != null && state.cycleCount >= 2)
            _PatternLine(state: state)
          else
            _NoPattern(state: state),
          if (state.avg != null && state.cycleCount >= 2) ...[
            const SizedBox(height: 16),
            const _Histogram(),
          ],
        ],
      ),
    );
  }
}

class _NoPattern extends StatelessWidget {
  final CycleState state;
  const _NoPattern({required this.state});

  @override
  Widget build(BuildContext context) {
    return Text(
      state.cycleCount <= 1
          ? 'using the population prior until you log at least 2 period starts.'
          : 'not enough data yet. log a few cycles before any averages appear.',
      style: Type.body(size: 13, color: Tokens.graphite2, height: 1.45),
    );
  }
}

class _PatternLine extends StatelessWidget {
  final CycleState state;
  const _PatternLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final body = Type.body(size: 13, height: 1.45);
    final em = Type.mono(
      size: 13,
      color: Tokens.ink,
      weight: Tokens.fwMedium,
      letterSpacingEm: 0.0,
      height: 1.45,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'your last ', style: body),
          TextSpan(text: '${state.cycleCount} cycles', style: em),
          TextSpan(text: ' averaged ', style: body),
          TextSpan(text: state.avg!, style: em),
          TextSpan(text: '.\nflow length averaged ', style: body),
          TextSpan(text: state.avgFlow!, style: em),
          TextSpan(text: '.', style: body),
        ],
      ),
    );
  }
}

class _Histogram extends StatelessWidget {
  const _Histogram();

  // Same fixture as today.jsx (lines 357-368): 11 bars, 3 flow markers
  // labeled 28/29/30 (cycle lengths in days for those flow events).
  static const _bars = <_Bar>[
    _Bar(0.40, true, '28'),
    _Bar(0.20, false, null),
    _Bar(0.70, false, null),
    _Bar(0.60, false, null),
    _Bar(0.45, true, '29'),
    _Bar(0.15, false, null),
    _Bar(0.65, false, null),
    _Bar(0.55, false, null),
    _Bar(0.50, true, '30'),
    _Bar(0.18, false, null),
    _Bar(0.70, false, null),
  ];

  static const _barArea = 28.0;
  static const _labelArea = 14.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barArea + _labelArea,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _bars.length; i++) ...[
            Expanded(child: _BarView(bar: _bars[i])),
            if (i != _bars.length - 1) const SizedBox(width: _gap),
          ],
        ],
      ),
    );
  }
}

class _BarView extends StatelessWidget {
  final _Bar bar;
  const _BarView({required this.bar});

  @override
  Widget build(BuildContext context) {
    final color = bar.flow ? Tokens.oxide : Tokens.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _Histogram._barArea,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: (_Histogram._barArea * bar.h).clamp(
                4.0,
                _Histogram._barArea,
              ),
              decoration: BoxDecoration(color: color),
            ),
          ),
        ),
        SizedBox(
          height: _Histogram._labelArea,
          child: bar.label == null
              ? const SizedBox.shrink()
              : Center(
                  child: Text(
                    bar.label!,
                    style: Type.mono(
                      size: 9,
                      color: Tokens.graphite2,
                      letterSpacingEm: 0.0,
                      height: 1.0,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Bar {
  final double h;
  final bool flow;
  final String? label;
  const _Bar(this.h, this.flow, this.label);
}
