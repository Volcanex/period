import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class NumericSheet extends StatefulWidget {
  final String trackerId;
  final double? current;
  final ValueChanged<double> onSet;

  const NumericSheet({
    super.key,
    required this.trackerId,
    required this.current,
    required this.onSet,
  });

  @override
  State<NumericSheet> createState() => _NumericSheetState();
}

class _NumericSheetState extends State<NumericSheet> {
  late double val;
  late TrackerDef def;

  @override
  void initState() {
    super.initState();
    def = trackerDefs[widget.trackerId]!;
    val = widget.current ?? def.defaultValue;
  }

  void _dec() => setState(
        () => val = (val - def.step).clamp(def.min, def.max).toDouble().roundToStep(def.step),
      );
  void _inc() => setState(
        () => val = (val + def.step).clamp(def.min, def.max).toDouble().roundToStep(def.step),
      );

  String _display() {
    if (widget.trackerId == 'bbt') return val.toStringAsFixed(2);
    if (widget.trackerId == 'sleep') return val.toStringAsFixed(2);
    return val.toStringAsFixed(1);
  }

  List<double> _quickValues() {
    return switch (widget.trackerId) {
      'bbt' => const [97.40, 97.60, 97.80, 98.00, 98.20],
      'sleep' => const [5, 6, 7, 7.5, 8, 9],
      'weight' => const [140, 142, 144, 146],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: def.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _NumStepper(
            display: _display(),
            unit: def.unit,
            onDec: _dec,
            onInc: _inc,
          ),
          const SizedBox(height: 14),
          Text('QUICK VALUES', style: Type.eyebrow()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final q in _quickValues())
                _QuickChip(
                  label: widget.trackerId == 'bbt' ? q.toStringAsFixed(2) : _stripZero(q),
                  onTap: () => setState(() => val = q),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'save',
            onPressed: () {
              widget.onSet(val);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

String _stripZero(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

class _NumStepper extends StatelessWidget {
  final String display;
  final String unit;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _NumStepper({
    required this.display,
    required this.unit,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.graphite, width: Tokens.bwRule),
        borderRadius: BorderRadius.circular(Tokens.r2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.r2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepButton(label: '−', onTap: onDec, hasRight: true),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: display,
                          style: Type.display(
                            size: 30,
                            weight: Tokens.fwMedium,
                            height: 1.0,
                            letterSpacingEm: -0.02,
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (unit.isNotEmpty)
                          TextSpan(
                            text: ' $unit',
                            style: Type.mono(
                              size: 12,
                              color: Tokens.graphite2,
                              letterSpacingEm: 0.04,
                              height: 1.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _StepButton(label: '+', onTap: onInc, hasLeft: true),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool hasLeft;
  final bool hasRight;
  const _StepButton({
    required this.label,
    required this.onTap,
    this.hasLeft = false,
    this.hasRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: hasLeft
                  ? const BorderSide(color: Tokens.graphite, width: 1)
                  : BorderSide.none,
              right: hasRight
                  ? const BorderSide(color: Tokens.graphite, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Type.display(
                size: 22,
                weight: Tokens.fwMedium,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Tokens.bg,
            borderRadius: BorderRadius.circular(Tokens.r2),
            border: Border.all(color: Tokens.graphite, width: Tokens.bwRule),
          ),
          child: Text(
            label,
            style: Type.body(size: 12, weight: Tokens.fwMedium, height: 1.0),
          ),
        ),
      ),
    );
  }
}

extension _RoundToStep on double {
  double roundToStep(double step) {
    final factor = 1 / step;
    return (this * factor).round() / factor;
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Tokens.paper,
          border: Border(
            top: BorderSide(color: Tokens.graphite, width: Tokens.bwRule),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.r3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Tokens.graphite2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Type.display(
                      size: 18,
                      weight: Tokens.fwMedium,
                      height: 1.1,
                      letterSpacingEm: -0.01,
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'CLOSE',
                      style: Type.mono(
                        size: 11,
                        color: Tokens.graphite2,
                        letterSpacingEm: 0.06,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Tokens.ink,
          foregroundColor: Tokens.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.r2),
            side: const BorderSide(color: Tokens.ink, width: Tokens.bwRule),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: Type.body(
            size: 14,
            weight: Tokens.fwMedium,
            color: Tokens.paper,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
