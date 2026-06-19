import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Pill toggle. Off = paper bg with graphite border, on = ink bg.
/// Knob slides across.
class TrackerToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;

  const TrackerToggle({super.key, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const w = 36.0;
    const h = 20.0;
    const knob = 14.0;
    const pad = 2.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: w,
          height: h,
          child: AnimatedContainer(
            duration: Tokens.durFast,
            decoration: BoxDecoration(
              color: on ? Tokens.ink : Tokens.bg,
              border: Border.all(
                color: on ? Tokens.ink : Tokens.borderSoft,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(h / 2),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: Tokens.durFast,
                  curve: Tokens.ease,
                  left: on ? w - knob - pad - 2 : pad,
                  top: (h - knob) / 2 - 1,
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      color: on ? Tokens.paper : Tokens.graphite2,
                      borderRadius: BorderRadius.circular(knob / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
