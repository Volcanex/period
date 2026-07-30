import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import 'tracker_toggle.dart';

/// One condition-pack card. Title + toggle, description, and the list of
/// trackers the pack adds.
class TrackerPackCard extends StatelessWidget {
  final String name;
  final String desc;
  final List<String> adds;
  final int enabledCount;
  final bool on;
  final bool highlighted;
  final bool subdued;
  final String? statusLabel;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const TrackerPackCard({
    super.key,
    required this.name,
    required this.desc,
    required this.adds,
    required this.enabledCount,
    required this.on,
    this.highlighted = false,
    this.subdued = false,
    this.statusLabel,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onOpen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: highlighted
                ? Tokens.phaseCalLuteal
                : subdued
                ? Tokens.base
                : Tokens.bg,
            borderRadius: BorderRadius.circular(Tokens.r2),
            border: Border.all(
              color: highlighted
                  ? Tokens.graphite
                  : subdued
                  ? Tokens.borderSoft.withValues(alpha: 0.72)
                  : Tokens.borderSoft,
              width: highlighted ? Tokens.bwRule : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Type.display(
                        size: 14,
                        weight: Tokens.fwMedium,
                        height: 1.2,
                        color: subdued ? Tokens.graphite2 : Tokens.ink,
                      ),
                    ),
                  ),
                  if (statusLabel != null) ...[
                    _StatusPill(label: statusLabel!, subdued: subdued),
                    const SizedBox(width: 8),
                  ],
                  TrackerToggle(on: on, onTap: onToggle),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                highlighted ? '$desc\n\nOpened from insights' : desc,
                style: Type.body(
                  size: 12,
                  color: subdued
                      ? Tokens.graphite2.withValues(alpha: 0.82)
                      : Tokens.graphite2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniStat(label: 'trackers', value: '$enabledCount'),
                  _MiniStat(label: 'today', value: on ? 'On' : 'Off'),
                  _SmallAction(label: 'details', onTap: onOpen),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in adds)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Tokens.base,
                        borderRadius: BorderRadius.circular(Tokens.r1),
                        border: Border.all(color: Tokens.borderSoft, width: 1),
                      ),
                      child: Text(
                        a,
                        style: Type.mono(
                          size: 10,
                          color: subdued ? Tokens.graphite2 : Tokens.ink,
                          letterSpacingEm: 0.04,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool subdued;

  const _StatusPill({required this.label, required this.subdued});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: subdued ? Tokens.bg : Tokens.ink,
        borderRadius: BorderRadius.circular(Tokens.r1),
        border: Border.all(
          color: subdued ? Tokens.borderSoft : Tokens.ink,
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: Type.mono(
          size: 8.5,
          color: subdued ? Tokens.graphite2 : Tokens.bg,
          letterSpacingEm: 0.06,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value ${label.toUpperCase()}',
      style: Type.mono(
        size: 9.5,
        color: Tokens.graphite2,
        letterSpacingEm: 0.06,
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label.toUpperCase(),
        style: Type.mono(size: 9.5, color: Tokens.ink, letterSpacingEm: 0.06)
            .copyWith(
              decoration: TextDecoration.underline,
              decorationColor: Tokens.borderSoft,
            ),
      ),
    );
  }
}
