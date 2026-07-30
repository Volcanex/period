import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/tracker_catalog.dart';
import '../../api/contracts/tracker_pack.dart';
import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/number_stepper.dart';
import '../shared/top_bar.dart';
import '../today/widgets/section_box.dart';
import '../trackers/widgets/tracker_row.dart';
import 'widgets/segmented.dart';
import 'widgets/setting_row.dart';

/// Settings tab — local device controls and demo data status.
class SettingsScreen extends StatefulWidget {
  final bool darkMode;
  final int cycleLength;
  final int flowLength;
  final int todayTrackerCount;
  final int loggedDayCount;
  final int observationCount;
  final Map<String, bool> packEnabled;
  final TrackerCatalog catalog;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<int> onCycleLengthChanged;
  final ValueChanged<int> onFlowLengthChanged;
  final Map<String, dynamic> Function() exportSnapshot;
  final Future<void> Function() onResetDemoLogs;

  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.cycleLength,
    required this.flowLength,
    required this.todayTrackerCount,
    required this.loggedDayCount,
    required this.observationCount,
    required this.packEnabled,
    required this.catalog,
    required this.onDarkModeChanged,
    required this.onCycleLengthChanged,
    required this.onFlowLengthChanged,
    required this.exportSnapshot,
    required this.onResetDemoLogs,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final enabledPacks = widget.catalog.packs
        .where((pack) => _packOn(pack))
        .toList(growable: false);
    final enabledTrackerCount = enabledPacks
        .expand((pack) => pack.trackerCodes)
        .toSet()
        .length;

    return Column(
      children: [
        const TopBar(title: 'Settings'),
        Expanded(
          child: ContentPane(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SectionBox(
                  eyebrow: 'cycle defaults',
                  trailing: const SectionAction(
                    label: 'local model',
                    muted: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingRow(
                        label: 'Typical cycle',
                        meta:
                            'Used until your bleeding history has enough signal',
                        trailing: NumberStepper(
                          value: widget.cycleLength,
                          min: 21,
                          max: 45,
                          unit: 'd',
                          onChanged: widget.onCycleLengthChanged,
                        ),
                      ),
                      SettingRow(
                        label: 'Typical period',
                        meta: 'Flow prediction length',
                        trailing: NumberStepper(
                          value: widget.flowLength,
                          min: 1,
                          max: 10,
                          unit: 'd',
                          onChanged: widget.onFlowLengthChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'appearance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingRow(
                        label: 'Theme',
                        trailing: Segmented(
                          values: const ['light', 'dark'],
                          selected: widget.darkMode ? 'dark' : 'light',
                          onChanged: (v) =>
                              widget.onDarkModeChanged(v == 'dark'),
                        ),
                        meta: 'Saved on this device',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'tracker setup',
                  trailing: SectionAction(
                    label: '${enabledPacks.length} packs',
                    muted: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TrackerRow(
                        leading: '·',
                        name: 'Enabled trackers',
                        meta: '$enabledTrackerCount active',
                        trailing: Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Tokens.ink,
                        ),
                      ),
                      TrackerRow(
                        leading: '·',
                        name: 'Trackers on Today',
                        meta: '${widget.todayTrackerCount} quick logs',
                        trailing: Icon(
                          Icons.today_outlined,
                          size: 16,
                          color: Tokens.ink,
                        ),
                      ),
                      ...enabledPacks
                          .take(4)
                          .map(
                            (pack) => TrackerRow(
                              leading: '·',
                              name: pack.displayName,
                              meta: '${pack.trackerCodes.length} trackers',
                              trailing: const SizedBox(width: 16),
                            ),
                          ),
                      if (enabledPacks.length > 4)
                        TrackerRow(
                          leading: '·',
                          name: 'More enabled packs',
                          meta: '+${enabledPacks.length - 4}',
                          trailing: const SizedBox(width: 16),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'catalog',
                  trailing: SectionAction(
                    label: _apiLabel,
                    muted: widget.catalog.source == CatalogSource.loading,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingRow(
                        label: 'Tracker catalog',
                        meta: widget.catalog.provenanceLabel,
                        trailing: _StatusDot(
                          live: widget.catalog.source == CatalogSource.bundled,
                        ),
                      ),
                      const SettingRow(
                        label: 'Network',
                        meta: 'Never — no account, no server',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'data',
                  trailing: const SectionAction(
                    label: 'local-first',
                    muted: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TrackerRow(
                        leading: '·',
                        name: 'Logged days',
                        meta: '${widget.loggedDayCount}',
                        trailing: const SizedBox(width: 16),
                      ),
                      TrackerRow(
                        leading: '·',
                        name: 'Observation events',
                        meta: '${widget.observationCount}',
                        trailing: const SizedBox(width: 16),
                      ),
                      TrackerRow(
                        leading: '·',
                        name: 'Local snapshot',
                        meta: 'JSON',
                        trailing: const _ExportArrow(),
                        onTap: () => _showSnapshot(context),
                      ),
                      const SizedBox(height: 12),
                      _PrimaryButton(
                        label: 'View local snapshot',
                        onTap: () => _showSnapshot(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '[ export preview only · nothing leaves device unless you share ]',
                        textAlign: TextAlign.center,
                        style: Type.mono(
                          size: 10,
                          color: Tokens.graphite2,
                          letterSpacingEm: 0.08,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'privacy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingRow(
                        label: 'Storage',
                        meta: 'Local browser storage · no account sync',
                      ),
                      const SettingRow(
                        label: 'Network',
                        meta: 'Reads tracker catalog only · no health uploads',
                      ),
                      SettingRow(
                        label: 'Reset demo logs',
                        meta: 'Clears local observations · keeps setup',
                        trailing: GestureDetector(
                          onTap: () => _confirmReset(context),
                          child: Text(
                            'RESET',
                            style: Type.mono(
                              size: 10,
                              color: Tokens.oxide,
                              letterSpacingEm: 0.08,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'about',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      SettingRow(label: 'Version', meta: '0.1.0 · web demo'),
                      SettingRow(
                        label: 'Contracts',
                        meta: 'Tracker catalog · v1 endpoints',
                      ),
                      SettingRow(
                        label: 'Medical status',
                        meta: 'Not a diagnostic device',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Text(
                  '[ Sequence is not a diagnostic device ]',
                  textAlign: TextAlign.center,
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.08,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _apiLabel => switch (widget.catalog.source) {
    CatalogSource.bundled => 'on device',
    CatalogSource.error => 'unavailable',
    CatalogSource.loading => 'loading',
  };

  bool _packOn(TrackerPack pack) =>
      widget.packEnabled[pack.code] ?? pack.enabledByDefault;

  Future<void> _showSnapshot(BuildContext context) async {
    final snapshot = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.exportSnapshot());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SnapshotSheet(snapshot: snapshot),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResetSheet(onConfirm: widget.onResetDemoLogs),
    );
    if (confirmed == true && context.mounted) {
      _showSnack(context, 'Demo logs reset');
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(msg, style: Type.body(size: 13, color: Tokens.paper)),
        backgroundColor: Tokens.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool live;

  const _StatusDot({required this.live});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: live ? Tokens.sky4 : Tokens.oxide,
        shape: BoxShape.circle,
        border: Border.all(color: Tokens.borderSoft),
      ),
    );
  }
}

class _SnapshotSheet extends StatelessWidget {
  final String snapshot;

  const _SnapshotSheet({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: Tokens.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: Tokens.borderSoft),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('LOCAL SNAPSHOT', style: Type.eyebrow())),
                IconButton(
                  tooltip: 'Copy snapshot',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: snapshot));
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.copy, size: 18, color: Tokens.ink),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 18, color: Tokens.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Tokens.base,
                  border: Border.all(color: Tokens.borderSoft),
                  borderRadius: BorderRadius.circular(Tokens.r2),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    snapshot,
                    style: Type.mono(size: 10, color: Tokens.ink, height: 1.35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetSheet extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const _ResetSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: Tokens.borderSoft),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('RESET DEMO LOGS', style: Type.eyebrow()),
            const SizedBox(height: 12),
            Text(
              'This clears local bleeding, mood, tracker, note, and observation data. Theme and enabled tracker packs stay as they are.',
              style: Type.body(size: 14, color: Tokens.ink, height: 1.35),
            ),
            const SizedBox(height: 14),
            _PrimaryButton(
              label: 'Reset local logs',
              onTap: () async {
                await onConfirm();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                textAlign: TextAlign.center,
                style: Type.mono(
                  size: 10,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportArrow extends StatelessWidget {
  const _ExportArrow();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.ios_share, size: 16, color: Tokens.ink);
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Tokens.ink,
            borderRadius: BorderRadius.circular(Tokens.r2),
          ),
          child: Text(
            label,
            style: Type.body(
              size: 14,
              color: Tokens.paper,
              weight: Tokens.fwMedium,
            ),
          ),
        ),
      ),
    );
  }
}
