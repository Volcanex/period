import 'package:flutter/material.dart';

import '../../api/tracker_catalog.dart';
import '../../api/contracts/tracker_definition.dart';
import '../../api/contracts/tracker_pack.dart';
import '../../data/models.dart';
import '../../state/api_scope.dart';
import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../shared/top_bar.dart';
import '../today/sheets/sheet_scaffold.dart';
import '../today/widgets/section_box.dart';
import 'widgets/tracker_pack_card.dart';
import 'widgets/tracker_row.dart';

/// Trackers tab — browse tracker packs and see which logging fields are on
/// Today. Pack state is the source of truth; there is no separate per-tracker
/// layer in the product UI.
class TrackersScreen extends StatefulWidget {
  final Map<String, bool> packEnabled;
  final void Function(String packCode, bool enabled) onSetPackEnabled;
  final String? focusPackCode;

  const TrackersScreen({
    super.key,
    required this.packEnabled,
    required this.onSetPackEnabled,
    this.focusPackCode,
  });

  @override
  State<TrackersScreen> createState() => _TrackersScreenState();
}

class _TrackersScreenState extends State<TrackersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ApiScope.of(context).state;
    final allDefinitions = _allDefinitions(catalog);
    final definitions = _filterDefinitions(_visibleDefinitions(catalog));
    final packs = _filterPacks(_visiblePacks(catalog), allDefinitions);

    return Column(
      children: [
        TopBar(
          title: 'Trackers',
          trailing: [
            _TopIconButton(
              icon: _searchOpen ? Icons.close : Icons.search,
              onTap: _toggleSearch,
            ),
          ],
        ),
        Expanded(
          child: ContentPane(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (_searchOpen) ...[
                  _TrackerSearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                ],

                // tracker packs
                SectionBox(
                  eyebrow: 'tracker packs',
                  trailing: const SectionAction(
                    label: 'does not diagnose',
                    muted: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (packs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No packs match this search.',
                            style: Type.body(size: 13, color: Tokens.graphite2),
                          ),
                        )
                      else
                        for (final pack in packs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TrackerPackCard(
                              name: pack.displayName,
                              desc: pack.description,
                              adds: _packAdds(pack, allDefinitions),
                              enabledCount: _enabledCount(pack, allDefinitions),
                              on: _packOn(pack),
                              highlighted: widget.focusPackCode == pack.code,
                              subdued: _packStatus(pack).subdued,
                              statusLabel: _packStatus(pack).label,
                              onToggle: () => widget.onSetPackEnabled(
                                pack.code,
                                !_packOn(pack),
                              ),
                              onOpen: () =>
                                  _openPackSheet(context, pack, allDefinitions),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SectionBox(
                  eyebrow: 'trackers on today',
                  trailing: SectionAction(
                    label: '${definitions.length} on',
                    muted: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (definitions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No trackers match this search.',
                            style: Type.body(size: 13, color: Tokens.graphite2),
                          ),
                        )
                      else
                        for (final def in definitions)
                          TrackerRow(
                            leading: '',
                            name: def.displayName,
                            meta: _kindLabel(def),
                            trailing: const _RowStateLabel('on today'),
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Text(
                  '[ turn packs on to add Today trackers · observations stay local ]',
                  textAlign: TextAlign.center,
                  style: Type.mono(
                    size: 10,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.08,
                  ),
                ),
                const SizedBox(height: 6),
                _CatalogProvenance(catalog: catalog),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _packOn(TrackerPack pack) =>
      widget.packEnabled[pack.code] ?? pack.enabledByDefault;

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  List<TrackerDefinition> _allDefinitions(TrackerCatalog catalog) =>
      catalog.definitions.isNotEmpty
      ? catalog.definitions
      : _fixtureDefinitions();

  List<TrackerDefinition> _visibleDefinitions(TrackerCatalog catalog) {
    final definitions = _allDefinitions(catalog);
    final enabledPackCodes = {
      for (final pack in _visiblePacks(catalog))
        if (_packOn(pack)) ...pack.trackerCodes,
    };
    final filtered = definitions
        .where(
          (d) => d.temporalGrain == 'day' && enabledPackCodes.contains(d.code),
        )
        .toList();
    filtered.sort((a, b) {
      final byPriority = b.calendarPriority.compareTo(a.calendarPriority);
      if (byPriority != 0) return byPriority;
      return a.displayName.compareTo(b.displayName);
    });
    return filtered;
  }

  List<TrackerPack> _visiblePacks(TrackerCatalog catalog) =>
      catalog.packs.isNotEmpty ? catalog.packs : _fixturePacks();

  List<TrackerDefinition> _filterDefinitions(List<TrackerDefinition> defs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return defs;
    return [
      for (final def in defs)
        if (_matchesDef(def, q)) def,
    ];
  }

  List<TrackerPack> _filterPacks(
    List<TrackerPack> packs,
    List<TrackerDefinition> definitions,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return packs;
    final byCode = {for (final def in definitions) def.code: def};
    return [
      for (final pack in packs)
        if (pack.displayName.toLowerCase().contains(q) ||
            pack.description.toLowerCase().contains(q) ||
            pack.trackerCodes.any(
              (code) =>
                  code.toLowerCase().contains(q) ||
                  (byCode[code]?.displayName.toLowerCase().contains(q) ??
                      false),
            ))
          pack,
    ];
  }

  bool _matchesDef(TrackerDefinition def, String q) {
    return def.code.toLowerCase().contains(q) ||
        def.displayName.toLowerCase().contains(q) ||
        (def.unit?.toLowerCase().contains(q) ?? false) ||
        (def.allowedValues?.any((value) => value.toLowerCase().contains(q)) ??
            false);
  }

  List<String> _packAdds(
    TrackerPack pack,
    List<TrackerDefinition> definitions,
  ) {
    final byCode = {for (final d in definitions) d.code: d};
    return [
      for (final code in pack.trackerCodes.take(5))
        byCode[code]?.displayName ?? code,
    ];
  }

  String _kindLabel(TrackerDefinition d) {
    if (d.isNumeric) return d.unit == null ? 'numeric' : 'numeric · ${d.unit}';
    if (d.isEnum) return 'choice';
    if (d.isBoolean) return 'toggle';
    return d.valueType;
  }

  int _enabledCount(TrackerPack pack, List<TrackerDefinition> definitions) {
    final byCode = {for (final d in definitions) d.code};
    return pack.trackerCodes.where(byCode.contains).length;
  }

  List<TrackerDefinition> _packDefinitions(
    TrackerPack pack,
    List<TrackerDefinition> definitions,
  ) {
    final byCode = {for (final d in definitions) d.code: d};
    return [
      for (final code in pack.trackerCodes)
        if (byCode[code] != null) byCode[code]!,
    ];
  }

  Future<void> _openPackSheet(
    BuildContext context,
    TrackerPack pack,
    List<TrackerDefinition> definitions,
  ) async {
    final packDefs = _packDefinitions(pack, definitions);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Tokens.ink.withValues(alpha: 0.6),
      builder: (_) => _PackDetailSheet(
        pack: pack,
        definitions: packDefs,
        on: _packOn(pack),
        status: _packStatus(pack),
        onTogglePack: () => widget.onSetPackEnabled(pack.code, !_packOn(pack)),
      ),
    );
  }
}

class _PackDetailSheet extends StatelessWidget {
  final TrackerPack pack;
  final List<TrackerDefinition> definitions;
  final bool on;
  final _PackStatus status;
  final VoidCallback onTogglePack;

  const _PackDetailSheet({
    required this.pack,
    required this.definitions,
    required this.on,
    required this.status,
    required this.onTogglePack,
  });

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: pack.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pack.description,
            style: Type.body(size: 14, color: Tokens.graphite2, height: 1.4),
          ),
          if (status.sheetNote != null) ...[
            const SizedBox(height: 10),
            _PackStatusNote(status: status),
          ],
          if (pack.clinicalNote != null && pack.clinicalNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pack.clinicalNote!,
              style: Type.body(size: 13, color: Tokens.graphite2, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PackMetric(
                  label: 'trackers',
                  value: '${definitions.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PackMetric(label: 'state', value: on ? 'On' : 'Off'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SheetPrimaryButton(
            label: on ? 'Turn pack off' : 'Turn pack on',
            onPressed: () {
              onTogglePack();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 16),
          Text('TRACKERS', style: Type.eyebrow()),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Tokens.bg,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            child: Column(
              children: [
                for (final def in definitions)
                  TrackerRow(
                    leading: '',
                    name: def.displayName,
                    meta: _sheetKindLabel(def),
                    trailing: _RowStateLabel(on ? 'on today' : 'in pack'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '[ packs add logging fields to Today · not diagnosis ]',
            textAlign: TextAlign.center,
            style: Type.mono(
              size: 10,
              color: Tokens.graphite2,
              letterSpacingEm: 0.08,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowStateLabel extends StatelessWidget {
  final String label;

  const _RowStateLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Type.mono(
        size: 9.5,
        color: Tokens.graphite2,
        letterSpacingEm: 0.06,
        height: 1.0,
      ),
    );
  }
}

class _PackStatusNote extends StatelessWidget {
  final _PackStatus status;

  const _PackStatusNote({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status.subdued ? Tokens.base : Tokens.phaseCalLuteal,
        borderRadius: BorderRadius.circular(Tokens.r1),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Text(
        status.sheetNote!,
        style: Type.body(size: 13, color: Tokens.graphite2, height: 1.35),
      ),
    );
  }
}

class _PackStatus {
  final String? label;
  final String? sheetNote;
  final bool subdued;

  const _PackStatus({this.label, this.sheetNote, this.subdued = false});
}

_PackStatus _packStatus(TrackerPack pack) {
  return switch (pack.code) {
    'pms_pmdd_support' => const _PackStatus(
      label: 'model first',
      sheetNote:
          'PMDD / PMS is the first specialist model pass. The trackers work now; backend detection will be designed with proper prospective-data rules before it appears in Insights.',
    ),
    'base_symptoms' => const _PackStatus(),
    _ => const _PackStatus(
      label: 'coming soon',
      subdued: true,
      sheetNote:
          'This specialist model is coming later. You can still turn the pack on now to add its logging fields to Today.',
    ),
  };
}

class _PackMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PackMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Type.mono(
              size: 9,
              color: Tokens.graphite2,
              letterSpacingEm: 0.06,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Type.display(size: 18, weight: Tokens.fwMedium, height: 1.0),
          ),
        ],
      ),
    );
  }
}

String _sheetKindLabel(TrackerDefinition d) {
  if (d.isNumeric) return 'number';
  if (d.isEnum) return 'choice';
  if (d.isBoolean) return 'toggle';
  if (d.isText) return 'text';
  return d.valueType;
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: Tokens.ink),
        ),
      ),
    );
  }
}

class _TrackerSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _TrackerSearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: Tokens.graphite2),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              cursorColor: Tokens.ink,
              style: Type.body(size: 14, color: Tokens.ink),
              decoration: InputDecoration(
                hintText: 'Search trackers or packs',
                hintStyle: Type.body(size: 14, color: Tokens.graphite2),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<TrackerDefinition> _fixtureDefinitions() => [
  for (final def in trackerDefs.values)
    TrackerDefinition(
      code: def.id,
      displayName: def.name,
      valueType: def.kind == TrackerKind.numeric ? 'numeric' : 'enum',
      temporalGrain: 'day',
      calendarLayer: def.kind == TrackerKind.numeric ? 'vital' : 'symptom',
      calendarPriority: def.kind == TrackerKind.numeric ? 30 : 40,
      unit: def.unit.isEmpty ? null : def.unit,
      version: 'fixture',
      evidence: const [],
    ),
];

List<TrackerPack> _fixturePacks() => [
  TrackerPack(
    code: 'base_symptoms',
    displayName: 'Base symptoms',
    description: 'Core period, symptom, mood, and vital trackers.',
    trackerCodes: const [
      'period_bleeding',
      'cramps',
      'pelvic_pain',
      'headache',
      'fatigue',
      'mood',
      'sleep_hours',
      'basal_body_temperature',
      'weight',
    ],
    enabledByDefault: true,
    evidence: const [],
  ),
];

/// Tiny status pill showing that the catalog is on-device. Amber only if the
/// bundled asset failed to decode, which is a packaging fault worth seeing.
class _CatalogProvenance extends StatelessWidget {
  final TrackerCatalog catalog;
  const _CatalogProvenance({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (catalog.source) {
      CatalogSource.bundled => const Color(0xFF3B8C5F), // green-ish
      CatalogSource.error => Tokens.oxide,
      CatalogSource.loading => Tokens.graphite2,
    };
    return GestureDetector(
      onTap: () => ApiScope.read(context).refresh(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'CATALOG · ${catalog.provenanceLabel.toUpperCase()}',
                style: Type.mono(
                  size: 9.5,
                  color: Tokens.graphite2,
                  letterSpacingEm: 0.08,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
