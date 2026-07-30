import 'dart:async';

import 'package:flutter/material.dart';

import 'api/analyzer_repository.dart';
import 'api/tracker_catalog.dart';
import 'api/contracts/tracker_definition.dart';
import 'data/clock.dart';
import 'data/models.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shared/tab_bar.dart';
import 'screens/today/today_screen.dart';
import 'screens/trackers/trackers_screen.dart';
import 'state/api_scope.dart';
import 'state/local_period_store.dart';
import 'theme/tokens.dart';

/// Holds the cross-tab state (mirrors `App` in `main.jsx`) and routes between
/// the production demo tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final LocalPeriodStore store;
  late final AnalyzerRepository _analyzerRepo;
  AppTab tab = AppTab.today;

  // Tweaks that the design's tweaks panel surfaces.
  bool showMiniRing = true;
  bool compact = false;
  String? focusTrackerPackCode;

  @override
  void initState() {
    super.initState();
    store = LocalPeriodStore()..addListener(_onStoreChanged);
    _analyzerRepo = AnalyzerRepository()..addListener(_onAnalyzerChanged);
    unawaited(store.load());
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    store.dispose();
    _analyzerRepo.removeListener(_onAnalyzerChanged);
    _analyzerRepo.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    Tokens.setDark(store.darkMode);
    setState(() {});
  }

  void _onAnalyzerChanged() => setState(() {});

  void _triggerAnalyzers() {
    if (!store.loaded || _analyzerRepo.isLoading) return;
    final observations =
        store.observations.map((e) => e.toJson()).toList();
    unawaited(_analyzerRepo.evaluate(observations, 'subject-local-1'));
  }

  void _onTabChanged(AppTab t) {
    setState(() => tab = t);
    if (t == AppTab.insights && !_analyzerRepo.hasResults) {
      _triggerAnalyzers();
    }
  }

  Widget _screen() {
    if (!store.loaded) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.ink),
        ),
      );
    }

    final today = Clock.today;
    final todayLog = store.logFor(today);
    final cs = store.cycleStateFor(today);
    final catalog = ApiScope.of(context).state;
    final catalogDefinitions = {
      for (final definition in catalog.definitions) definition.code: definition,
    };
    final activeDayDefinitions = _activeDayDefinitions(
      catalog: catalog,
      packEnabled: store.packEnabled,
    );
    return switch (tab) {
      AppTab.today => TodayScreen(
        cycleState: cs,
        todayTrackers: _todayTrackerCodes(activeDayDefinitions),
        showMiniRing: showMiniRing,
        compact: compact,
        bleeding: todayLog.bleeding,
        onBleedingChanged: (b) => store.setBleeding(today, b),
        symptoms: todayLog.symptoms,
        symptomNotes: todayLog.symptomNotes,
        symptomLabels: _todaySymptomLabels(activeDayDefinitions),
        onSymptomChanged: (symptom, sev, note) =>
            store.setSymptom(today, symptom, sev, note),
        mood: todayLog.mood,
        onMoodChanged: (m) => store.setMood(today, m),
        numericValues: todayLog.numericValues,
        onNumericChanged: (id, value) => store.setNumeric(today, id, value),
        enumValues: todayLog.enumValues,
        onEnumChanged: (id, value) => store.setEnumValue(today, id, value),
        booleanValues: todayLog.booleanValues,
        onBooleanChanged: (id, value) =>
            store.setBooleanValue(today, id, value),
        textValues: todayLog.textValues,
        onTextChanged: (id, value) => store.setTextValue(today, id, value),
        catalogDefinitions: catalogDefinitions,
        note: todayLog.note,
        onNoteChanged: (n) => store.setNote(today, n),
        darkMode: store.darkMode,
        onToggleDarkMode: () => store.setDarkMode(!store.darkMode),
        onOpenTrackers: () => setState(() => tab = AppTab.trackers),
        onOpenSettings: () => setState(() => tab = AppTab.settings),
      ),
      AppTab.calendar => CalendarScreen(
        logFor: store.logFor,
        activeDefinitions: activeDayDefinitions,
        onBleedingChanged: store.setBleeding,
        onSymptomChanged: store.setSymptom,
        onMoodChanged: store.setMood,
        onNumericChanged: store.setNumeric,
        onEnumChanged: store.setEnumValue,
        onBooleanChanged: store.setBooleanValue,
        onTextChanged: store.setTextValue,
        onNoteChanged: store.setNote,
      ),
      AppTab.insights => InsightsScreen(
        cycleState: cs,
        loggedDayCount: store.loggedDayCount,
        packEnabled: store.packEnabled,
        analyzerResults: _analyzerRepo.results,
        onOpenTrackerPack: (packCode) {
          store.setPackEnabled(packCode, true);
          setState(() {
            focusTrackerPackCode = packCode;
            tab = AppTab.trackers;
          });
        },
        onOpenCycleHistory: () => setState(() => tab = AppTab.calendar),
        onRefreshAnalyzers: _triggerAnalyzers,
      ),
      AppTab.trackers => TrackersScreen(
        packEnabled: store.packEnabled,
        onSetPackEnabled: store.setPackEnabled,
        focusPackCode: focusTrackerPackCode,
      ),
      AppTab.settings => SettingsScreen(
        darkMode: store.darkMode,
        cycleLength: store.cycleLen,
        flowLength: store.flowLen,
        todayTrackerCount: _todayTrackerCodes(activeDayDefinitions).length,
        loggedDayCount: store.loggedDayCount,
        observationCount: store.observationCount,
        packEnabled: store.packEnabled,
        catalog: catalog,
        onDarkModeChanged: store.setDarkMode,
        onCycleLengthChanged: store.setCycleLength,
        onFlowLengthChanged: store.setFlowLength,
        exportSnapshot: store.exportSnapshot,
        onResetDemoLogs: store.resetDemoLogs,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (store.loaded) Tokens.setDark(store.darkMode);
    return Container(
      color: Tokens.base,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(bottom: 64, child: _screen()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomTabBar(
                current: tab,
                onChanged: _onTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _todayTrackerCodes(List<TrackerDefinition> activeDefinitions) {
  return [
    for (final definition in activeDefinitions)
      if (!_inlineTodayCodes.contains(definition.code) &&
          _symptomChipLabel(definition) == null)
        definition.code,
  ];
}

const _inlineTodayCodes = {'period_bleeding', 'mood', 'note'};

List<String> _todaySymptomLabels(List<TrackerDefinition> activeDefinitions) {
  final labels = <String>[...symptomsList];
  for (final definition in activeDefinitions) {
    final label = _symptomChipLabel(definition);
    if (label != null && !labels.contains(label)) labels.add(label);
  }
  return labels;
}

String? _symptomChipLabel(TrackerDefinition definition) {
  if (definition.calendarLayer != 'symptom' ||
      definition.temporalGrain != 'day') {
    return null;
  }
  final allowed = definition.allowedValues ?? const <String>[];
  final severityLike =
      definition.isEnum &&
      allowed.contains('none') &&
      allowed.contains('mild') &&
      allowed.contains('moderate') &&
      allowed.contains('severe');
  if (!severityLike) return null;

  return switch (definition.code) {
    'pelvic_pain' => 'pelvic pain',
    'migraine' => 'headache',
    'breast_tenderness' => 'tender',
    'bloating' => 'bloated',
    'acne_severity' => 'acne',
    'energy' => 'low energy',
    'anxiety_severity' => 'anxiety',
    'depression_severity' => 'depression',
    _ => definition.displayName.toLowerCase().replaceFirst(
      RegExp(r'\s+severity$'),
      '',
    ),
  };
}

List<TrackerDefinition> _activeDayDefinitions({
  required TrackerCatalog catalog,
  required Map<String, bool> packEnabled,
}) {
  final definitions = catalog.definitions;
  final packs = catalog.packs;
  if (definitions.isEmpty) return const [];
  final enabledCodes = <String>{};
  for (final pack in packs) {
    final on = packEnabled[pack.code] ?? pack.enabledByDefault;
    if (on) enabledCodes.addAll(pack.trackerCodes);
  }
  final filtered = [
    for (final definition in definitions)
      if (definition.temporalGrain == 'day' &&
          enabledCodes.contains(definition.code))
        definition,
  ];
  filtered.sort((a, b) {
    final byPriority = b.calendarPriority.compareTo(a.calendarPriority);
    if (byPriority != 0) return byPriority;
    return a.displayName.compareTo(b.displayName);
  });
  return filtered;
}
