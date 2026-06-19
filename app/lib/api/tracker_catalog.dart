import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'contracts/tracker_definition.dart';
import 'contracts/tracker_pack.dart';

/// Provenance for the catalog — was it fetched live, served from a cached
/// copy, or did the network fail and we fell back to bundled defaults?
enum CatalogSource { server, cached, fallback, loading }

@immutable
class TrackerCatalog {
  final List<TrackerDefinition> definitions;
  final List<TrackerPack> packs;
  final CatalogSource source;
  final String? error;
  final DateTime? fetchedAt;

  const TrackerCatalog({
    required this.definitions,
    required this.packs,
    required this.source,
    this.error,
    this.fetchedAt,
  });

  /// Empty initial state — used while the first fetch is in flight.
  const TrackerCatalog.loading()
    : definitions = const [],
      packs = const [],
      source = CatalogSource.loading,
      error = null,
      fetchedAt = null;

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
    CatalogSource.server => 'live · ${definitions.length} trackers',
    CatalogSource.cached => 'cached · ${definitions.length} trackers',
    CatalogSource.fallback => 'offline · using bundled defaults',
    CatalogSource.loading => 'loading…',
  };
}

/// Fetches the canonical tracker definitions + packs from the backend.
/// Falls back to bundled defaults if the API can't be reached so the app
/// is always usable (per the local-first posture).
class TrackerCatalogRepository extends ChangeNotifier {
  final ApiClient _client;
  TrackerCatalog _state = const TrackerCatalog.loading();

  TrackerCatalogRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  TrackerCatalog get state => _state;

  /// Kick off a refresh. Always swaps to a non-loading state on completion
  /// (server, cached, or fallback). Safe to call repeatedly.
  Future<void> refresh() async {
    try {
      // Fetch definitions and packs in parallel — they're both small.
      final results = await Future.wait([
        _client.getJson('/api/v1/tracker-definitions'),
        _client.getJson('/api/v1/tracker-packs'),
      ]);
      final defs = (results[0] as List)
          .map(
            (e) =>
                TrackerDefinition.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false);
      final packs = (results[1] as List)
          .map((e) => TrackerPack.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      _state = TrackerCatalog(
        definitions: defs,
        packs: packs,
        source: CatalogSource.server,
        fetchedAt: DateTime.now(),
      );
      notifyListeners();
    } on ApiError catch (e) {
      // Network failure → bundled fallback. Keeps the app working.
      debugPrint('Tracker catalog refresh failed, using fallback: $e');
      _state = TrackerCatalog(
        definitions: _bundledDefinitions,
        packs: _bundledPacks,
        source: CatalogSource.fallback,
        error: e.message,
      );
      notifyListeners();
    } catch (e, st) {
      debugPrint('Tracker catalog refresh threw $e\n$st');
      _state = TrackerCatalog(
        definitions: _bundledDefinitions,
        packs: _bundledPacks,
        source: CatalogSource.fallback,
        error: '$e',
      );
      notifyListeners();
    }
  }
}

// ---- bundled defaults ----
//
// Trimmed mirror of the FastAPI fixtures so the app never shows an empty
// trackers tab. Real shape comes from `/api/v1/tracker-definitions`; this
// is just enough to keep the existing UI populated until that lands.
//
// Codes match the backend contracts (`basal_body_temperature`, not `bbt`).
// The screens still render id-based fixtures from `data/models.dart` — those
// will swap to canonical codes in a follow-up pass.

final _evidence = <TrackerEvidence>[
  const TrackerEvidence(
    source: 'bundled fallback',
    assumption: 'Used when the backend is unreachable.',
    confidence: 0.0,
    version: 'fallback',
    reviewStatus: 'draft',
  ),
];

final _bundledDefinitions = <TrackerDefinition>[
  TrackerDefinition(
    code: 'period_bleeding',
    displayName: 'Period bleeding',
    valueType: 'enum',
    temporalGrain: 'day',
    calendarLayer: 'bleeding',
    calendarPriority: 95,
    allowedValues: const ['none', 'spotting', 'light', 'medium', 'heavy'],
    version: 'fallback',
    evidence: _evidence,
  ),
  TrackerDefinition(
    code: 'cramps',
    displayName: 'Cramps',
    valueType: 'enum',
    temporalGrain: 'day',
    calendarLayer: 'symptom',
    calendarPriority: 50,
    allowedValues: const ['none', 'mild', 'moderate', 'severe'],
    version: 'fallback',
    evidence: _evidence,
  ),
  TrackerDefinition(
    code: 'mood',
    displayName: 'Mood',
    valueType: 'enum',
    temporalGrain: 'day',
    calendarLayer: 'mood',
    calendarPriority: 40,
    allowedValues: const ['low', 'neutral', 'good', 'anxious', 'irritable'],
    version: 'fallback',
    evidence: _evidence,
  ),
  TrackerDefinition(
    code: 'sleep_hours',
    displayName: 'Sleep',
    valueType: 'numeric',
    temporalGrain: 'day',
    calendarLayer: 'vital',
    calendarPriority: 30,
    unit: 'h',
    version: 'fallback',
    evidence: _evidence,
  ),
  TrackerDefinition(
    code: 'basal_body_temperature',
    displayName: 'Basal body temperature',
    valueType: 'numeric',
    temporalGrain: 'day',
    calendarLayer: 'vital',
    calendarPriority: 35,
    unit: '°F',
    version: 'fallback',
    evidence: _evidence,
  ),
  TrackerDefinition(
    code: 'weight',
    displayName: 'Weight',
    valueType: 'numeric',
    temporalGrain: 'day',
    calendarLayer: 'vital',
    calendarPriority: 25,
    unit: 'lb',
    version: 'fallback',
    evidence: _evidence,
  ),
];

final _bundledPacks = <TrackerPack>[
  TrackerPack(
    code: 'base_symptoms',
    displayName: 'Base symptoms',
    description: 'Universal symptom and cycle logging.',
    trackerCodes: const [
      'period_bleeding',
      'cramps',
      'mood',
      'sleep_hours',
      'basal_body_temperature',
      'weight',
    ],
    enabledByDefault: true,
    evidence: _evidence,
  ),
];
