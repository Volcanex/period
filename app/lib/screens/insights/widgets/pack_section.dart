import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../calendar/widgets/dashed_border_box.dart';
import '../../today/widgets/section_box.dart';
import 'pain_map.dart';

class PackStat {
  final String label;
  final String value;
  final String sub;
  const PackStat({required this.label, required this.value, required this.sub});
}

/// A per-pack insights block. Eyebrow with glyph + on/off, content card with
/// optional chart (e.g. pain map for endo), stat list with hairline-dashed
/// dividers, footer description, and a "turn on" CTA when off.
class PackSection extends StatelessWidget {
  final String eyebrow;
  final bool on;
  final IconData glyph;
  final List<PackStat> stats;
  final String footer;
  final bool showPainMap;
  final List<int> painSeries;
  final VoidCallback onTurnOn;

  const PackSection({
    super.key,
    required this.eyebrow,
    required this.on,
    required this.glyph,
    required this.stats,
    required this.footer,
    required this.painSeries,
    this.showPainMap = false,
    required this.onTurnOn,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPainMap) ...[
          _PainMapHeader(),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: PainMap(values: painSeries, days: 28, peakDay: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'day 1',
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.04,
                ),
              ),
              Text(
                'day 14',
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.04,
                ),
              ),
              Text(
                'day 28',
                style: Type.mono(
                  size: 9,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.04,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (final s in stats) _StatRow(stat: s, faded: !on),
        const SizedBox(height: 12),
        Text(
          footer,
          style: Type.body(size: 12, color: Tokens.graphite2, height: 1.5),
        ),
        if (!on) ...[
          const SizedBox(height: 12),
          _TurnOnButton(label: eyebrow.split(' · ').first, onPressed: onTurnOn),
        ],
      ],
    );

    final wrapped = on
        ? Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            child: body,
          )
        : DashedBorderBox(
            color: Tokens.borderSoft,
            strokeWidth: 1,
            radius: Tokens.r2,
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Opacity(opacity: 0.78, child: body),
            ),
          );

    return SectionBox(
      eyebrow: eyebrow,
      bare: true,
      trailing: SectionAction(label: on ? 'on' : 'off', muted: true),
      child: wrapped,
    );
  }
}

class _PainMapHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'pelvic pain · cycle day map',
          style: Type.display(size: 13, weight: Tokens.fwMedium, height: 1.2),
        ),
        Text('0–4 SEVERITY', style: Type.eyebrow(size: 9)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final PackStat stat;
  final bool faded;
  const _StatRow({required this.stat, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stat.label, style: Type.body(size: 13, color: Tokens.ink)),
                if (stat.sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stat.sub,
                    style: Type.mono(
                      size: 10,
                      color: Tokens.graphite2,
                      letterSpacingEm: 0.04,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            stat.value,
            style: Type.display(
              size: 18,
              weight: Tokens.fwMedium,
              height: 1.0,
              letterSpacingEm: -0.01,
              color: faded ? Tokens.graphite2 : Tokens.ink,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _TurnOnButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _TurnOnButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.r1),
              border: Border.all(color: Tokens.ink, width: 1),
            ),
            child: Text(
              'turn on $label →',
              style: Type.mono(
                size: 11,
                color: Tokens.ink,
                letterSpacingEm: 0.02,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
