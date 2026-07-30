import 'package:flutter/material.dart';

import '../../data/clock.dart';
import '../../theme/tokens.dart';
import 'steps/cycle_length_step.dart';
import 'steps/last_period_step.dart';
import 'steps/privacy_step.dart';
import 'steps/tour_step.dart';

/// First-run setup.
///
/// One widget owning a step index rather than routes: `MaterialApp` here has
/// only `home:`, and pushing a route per step would bring Material page
/// transitions that look nothing like the rest of the app.
///
/// Nothing here touches the tracker catalog, so setup still works if that
/// fails to load.
class OnboardingFlow extends StatefulWidget {
  /// [lastPeriodStart] null means the user said they did not know.
  /// [cycleLength] null means "not sure" — the default stands rather than a
  /// guess being recorded as something they told us.
  final void Function({DateTime? lastPeriodStart, int? cycleLength}) onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  static const _stepCount = 4;

  int _step = 0;
  int _direction = 1;
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  bool _cycleLengthKnown = true;

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: Tokens.durSlow,
  )..forward();

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _go(int delta) => setState(() {
    _direction = delta;
    _step += delta;
  });

  void _finish() => widget.onComplete(
    lastPeriodStart: _lastPeriodStart,
    cycleLength: _cycleLengthKnown ? _cycleLength : null,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(-1);
      },
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entry, curve: Tokens.ease),
        child: Column(
          children: [
            _ProgressRule(step: _step, total: _stepCount),
            Expanded(
              child: AnimatedSwitcher(
                duration: Tokens.durBase,
                switchInCurve: Tokens.ease,
                switchOutCurve: Tokens.ease,
                // The default centres children and makes full-height steps
                // jump as they cross over.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_direction * 0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepWidget() => switch (_step) {
    0 => PrivacyStep(onNext: () => _go(1)),
    1 => LastPeriodStep(
      today: Clock.today,
      selected: _lastPeriodStart,
      onSelected: (d) => setState(() => _lastPeriodStart = d),
      onNext: () => _go(1),
      onSkip: () {
        setState(() => _lastPeriodStart = null);
        _go(1);
      },
    ),
    2 => CycleLengthStep(
      value: _cycleLength,
      onChanged: (v) => setState(() {
        _cycleLength = v;
        _cycleLengthKnown = true;
      }),
      onNext: () => _go(1),
      onSkip: () {
        setState(() => _cycleLengthKnown = false);
        _go(1);
      },
    ),
    _ => TourStep(onDone: _finish),
  };
}

class _ProgressRule extends StatelessWidget {
  final int step;
  final int total;

  const _ProgressRule({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: Tokens.borderSoft,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: Tokens.durBase,
          curve: Tokens.ease,
          widthFactor: (step + 1) / total,
          heightFactor: 1,
          child: ColoredBox(color: Tokens.ink),
        ),
      ),
    );
  }
}
