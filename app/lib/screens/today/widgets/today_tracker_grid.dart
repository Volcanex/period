import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/contracts/tracker_definition.dart';
import '../../../data/models.dart';
import '../../../theme/text_case.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class TodayTrackerGrid extends StatelessWidget {
  final List<String> trackerIds;
  final Map<String, double> values;
  final Map<String, Severity> symptoms;
  final String? mood;
  final BleedLevel? bleeding;
  final Map<String, String> enumValues;
  final Map<String, bool> booleanValues;
  final Map<String, String> textValues;
  final Map<String, TrackerDefinition> catalogDefinitions;
  final void Function(String trackerId) onTap;
  final void Function(String trackerId)? onLongPress;

  const TodayTrackerGrid({
    super.key,
    required this.trackerIds,
    required this.values,
    required this.symptoms,
    required this.mood,
    required this.bleeding,
    required this.enumValues,
    required this.booleanValues,
    required this.textValues,
    required this.catalogDefinitions,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        // Two up on a phone; wider columns add tiles rather than stretching
        // them, so a tile keeps roughly its phone size everywhere.
        final cols = (constraints.maxWidth / 200).floor().clamp(2, 4);
        final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final id in trackerIds)
              if (_displayFor(id) != null)
                SizedBox(
                  width: tileWidth,
                  child: _Tile(
                    def: _displayFor(id)!,
                    value: values[id],
                    labelValue: _labelValue(id),
                    onTap: () => onTap(id),
                    onLongPress: onLongPress == null
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            onLongPress!(id);
                          },
                  ),
                ),
          ],
        );
      },
    );
  }

  String? _labelValue(String id) {
    final numeric = values[id];
    if (numeric != null) return null;
    if (id == 'period_bleeding') return bleeding?.label;
    if (id == 'mood') return mood;
    if (enumValues[id] != null) return enumValues[id]!.replaceAll('_', ' ');
    if (booleanValues[id] != null) return booleanValues[id]! ? 'yes' : 'no';
    if (textValues[id] != null) return _shortText(textValues[id]!);
    final symptom = _symptomKey(id);
    if (symptom == null) return null;
    return symptoms[symptom]?.label;
  }

  _TrackerTileDef? _displayFor(String id) {
    final local = trackerDefs[id];
    if (local != null) {
      return _TrackerTileDef(
        id: local.id,
        name: local.name,
        unit: local.unit,
        placeholder: local.placeholder,
      );
    }
    final catalog = catalogDefinitions[id];
    if (catalog == null) return null;
    return _TrackerTileDef(
      id: catalog.code,
      name: catalog.displayName.toLowerCase(),
      unit: catalog.unit ?? '',
      placeholder: 'Tap to log',
    );
  }
}

class _Tile extends StatelessWidget {
  final _TrackerTileDef def;
  final double? value;
  final String? labelValue;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _Tile({
    required this.def,
    required this.value,
    required this.labelValue,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final set = value != null || labelValue != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
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
                        style:
                            Type.display(
                              size: 22,
                              weight: Tokens.fwMedium,
                              height: 1.0,
                              letterSpacingEm: -0.02,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
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
              else if (labelValue != null)
                Text(
                  displayCase(labelValue!),
                  style: Type.display(
                    size: 20,
                    weight: Tokens.fwMedium,
                    height: 1.0,
                    letterSpacingEm: -0.01,
                  ),
                  overflow: TextOverflow.ellipsis,
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
    if (id == 'bbt' || id == 'basal_body_temperature') {
      return v.toStringAsFixed(2);
    }
    if (id == 'weight') return v.toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }
}

class _TrackerTileDef {
  final String id;
  final String name;
  final String unit;
  final String placeholder;

  const _TrackerTileDef({
    required this.id,
    required this.name,
    required this.unit,
    required this.placeholder,
  });
}

String? _symptomKey(String id) => switch (id) {
  'pelvic_pain' => 'pelvic pain',
  'pain_with_sex' => 'pain with sex',
  'migraine' => 'headache',
  'breast_tenderness' => 'tender',
  'bloating' => 'bloated',
  'acne_severity' => 'acne',
  'anxiety_severity' => 'anxiety',
  'depression_severity' => 'depression',
  'energy' => 'low energy',
  'hot_flashes' => 'hot flashes',
  'night_sweats' => 'night sweats',
  'vaginal_dryness' => 'vaginal dryness',
  'hair_growth' => 'unwanted hair growth',
  'hair_thinning' => 'hair thinning',
  'cramps' ||
  'headache' ||
  'fatigue' ||
  'nausea' ||
  'irritability' ||
  'back_pain' => id.replaceAll('_', ' '),
  _ => null,
};

String _shortText(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 18) return trimmed;
  return '${trimmed.substring(0, 18)}...';
}
