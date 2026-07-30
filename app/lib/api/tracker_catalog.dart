import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'contracts/tracker_definition.dart';
import 'contracts/tracker_pack.dart';

/// Where the catalog came from. There is no network path — `bundled` is the
/// success case. `error` means the asset itself was missing or unparseable,
/// which is a build problem rather than a runtime condition.
enum CatalogSource { bundled, error, loading }

const _definitionsAsset = 'assets/catalog/tracker_definitions.json';
const _packsAsset = 'assets/catalog/tracker_packs.json';

@immutable
class TrackerCatalog {
  final List<TrackerDefinition> definitions;
  final List<TrackerPack> packs;
  final CatalogSource source;
  final String? error;

  const TrackerCatalog({
    required this.definitions,
    required this.packs,
    required this.source,
    this.error,
  });

  /// Empty initial state — used while the asset decode is in flight.
  const TrackerCatalog.loading()
    : definitions = const [],
      packs = const [],
      source = CatalogSource.loading,
      error = null;

  TrackerDefinition? defByCode(String code) {
    for (final d in definitions) {
      if (d.code == code) return d;
    }
    return null;
  }

  TrackerPack? packByCode(String code) {
    for (final p in packs) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// Short, mono-friendly provenance label for the trackers screen header.
  String get provenanceLabel => switch (source) {
    CatalogSource.bundled => 'On device · ${definitions.length} trackers',
    CatalogSource.error => 'Catalog unavailable',
    CatalogSource.loading => 'Loading…',
  };
}

/// Loads the canonical tracker definitions + packs from the bundled asset
/// catalog. Nothing leaves the device and there is no network dependency;
/// the JSON is generated from the Python registry by
/// `scripts/export_catalog.py`.
class TrackerCatalogRepository extends ChangeNotifier {
  final AssetBundle _bundle;
  TrackerCatalog _state = const TrackerCatalog.loading();

  TrackerCatalogRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  TrackerCatalog get state => _state;

  /// Read an asset and decode it in-process.
  ///
  /// Deliberately not `loadString`: that hands any payload over ~50KB to a
  /// background isolate via `compute`, and the definitions catalog is well
  /// past that. Spawning an isolate costs more than decoding 70KB inline, and
  /// the isolate never completes under widget tests' fake async, which makes
  /// the whole catalog silently unavailable in tests.
  Future<dynamic> _loadJson(String asset) async {
    final data = await _bundle.load(asset);
    return jsonDecode(utf8.decode(data.buffer.asUint8List()));
  }

  /// Decode the bundled catalog. Always swaps out of the loading state.
  /// Safe to call repeatedly.
  Future<void> refresh() async {
    try {
      final raw = await Future.wait([
        _loadJson(_definitionsAsset),
        _loadJson(_packsAsset),
      ]);
      final defs = (raw[0] as List)
          .map(
            (e) =>
                TrackerDefinition.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false);
      final packs = (raw[1] as List)
          .map((e) => TrackerPack.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      _state = TrackerCatalog(
        definitions: defs,
        packs: packs,
        source: defs.isEmpty ? CatalogSource.error : CatalogSource.bundled,
        error: defs.isEmpty ? 'bundled catalog is empty' : null,
      );
    } catch (e, st) {
      // A missing or malformed asset is a packaging fault, not a user-facing
      // network condition — surface it rather than silently degrading.
      debugPrint('Tracker catalog asset load failed: $e\n$st');
      _state = TrackerCatalog(
        definitions: const [],
        packs: const [],
        source: CatalogSource.error,
        error: '$e',
      );
    }
    notifyListeners();
  }
}
