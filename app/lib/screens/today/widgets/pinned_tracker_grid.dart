import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class PinnedTrackerGrid extends StatelessWidget {
  final List<String> pinnedIds;
  final Map<String, double> values;
  final void Function(String trackerId) onTap;

  const PinnedTrackerGrid({
    super.key,
    required this.pinnedIds,
    required this.values,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final id in pinnedIds)
              if (trackerDefs[id] != null)
                SizedBox(
                  width: tileWidth,
                  child: _Tile(
                    def: trackerDefs[id]!,
                    value: values[id],
                    onTap: () => onTap(id),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final TrackerDef def;
  final double? value;
  final VoidCallback onTap;

  const _Tile({required this.def, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final set = value != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: set ? Tokens.eggshell : Tokens.bg,
            border: Border.all(color: Tokens.borderSoft, width: 1),
            borderRadius: BorderRadius.circular(Tokens.r2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      def.name.toUpperCase(),
                      style: Type.mono(
                        size: 10,
                        color: set ? Tokens.ink : Tokens.graphite2,
                        letterSpacingEm: 0.08,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Tokens.oxide,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (value != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _formatValue(def.id, value!),
                        style: Type.display(
                          size: 22,
                          weight: Tokens.fwMedium,
                          height: 1.0,
                          letterSpacingEm: -0.02,
                        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      if (def.unit.isNotEmpty)
                        TextSpan(
                          text: ' ${def.unit}',
                          style: Type.mono(
                            size: 11,
                            color: Tokens.graphite2,
                            letterSpacingEm: 0.02,
                            height: 1.0,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Text(
                  def.placeholder,
                  style: Type.mono(
                    size: 11,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.04,
                    height: 1.0,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                set ? 'LOGGED · TODAY' : '—',
                style: Type.mono(
                  size: 9.5,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.06,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatValue(String id, double v) {
    if (id == 'bbt') return v.toStringAsFixed(2);
    if (id == 'weight') return v.toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }
}
