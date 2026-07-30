// Basic smoke test for the Today screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_app/api/contracts/tracker_definition.dart';
import 'package:period_app/data/clock.dart';
import 'package:period_app/data/models.dart';
import 'package:period_app/main.dart';
import 'package:period_app/model/cycle_model.dart';
import 'package:period_app/screens/calendar/sheets/day_sheet.dart';
import 'package:period_app/state/local_period_store.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// SharedPreferences writes under a `flutter.` prefix. Kept in one place so a
/// prefix change can't silently turn every seeded test into a first run.
const _storeKey = 'flutter.period.local_store.v1';

/// Seed a store blob. Any decodable blob counts as an existing user, so this
/// is also what keeps first-run setup out of the way of the shell tests.
void seedStore([String json = '{"setupComplete":true}']) =>
    SharedPreferences.setMockInitialValues({_storeKey: json});

void resetClock() => Clock.overrideCycleConfig(
  anchor: null,
  anchorKnown: true,
  cycleLen: null,
  flowLen: null,
  ovPeak: null,
);

void main() {
  // Clock is global static state; without this a test that leaves an unknown
  // anchor behind changes what unrelated later tests see.
  setUp(resetClock);
  tearDown(() {
    Clock.overrideNow(null);
    resetClock();
  });
  testWidgets('Today screen renders with date and bleeding card', (
    tester,
  ) async {
    // Pin the clock so the date assertion is stable across test runs.
    Clock.overrideNow(DateTime(2026, 5, 4));
    seedStore();

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('today'), findsWidgets);
    expect(find.text('bleeding'), findsOneWidget);
    expect(find.text('mon, may 4'), findsOneWidget);
  });

  testWidgets('Calendar past day opens editable local log sheet', (
    tester,
  ) async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore();

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').first);
    await tester.pumpAndSettle();

    expect(find.text('DAY LOG'), findsOneWidget);
    expect(find.text('bleeding'), findsOneWidget);
    expect(find.text('MOOD'), findsOneWidget);
  });

  testWidgets('Day sheet logs active boolean tracker from catalog', (
    tester,
  ) async {
    bool? sexLogged;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaySheet(
            date: DateTime(2026, 5, 4),
            phaseLabel: 'menstrual',
            kindLabel: 'logged flow',
            cycleDay: 1,
            log: const DayLog(),
            activeDefinitions: const [
              TrackerDefinition(
                code: 'sex',
                displayName: 'Sex',
                valueType: 'boolean',
                temporalGrain: 'day',
                calendarLayer: 'symptom',
                calendarPriority: 50,
                version: 'test',
                evidence: [],
              ),
            ],
            isToday: false,
            onBleedingChanged: (_) {},
            onSymptomChanged: (_, _, _) {},
            onMoodChanged: (_) {},
            onNumericChanged: (_, _) {},
            onEnumChanged: (_, _) {},
            onBooleanChanged: (code, value) {
              if (code == 'sex') sexLogged = value;
            },
            onTextChanged: (_, _) {},
            onNoteChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('sex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('yes'));
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(sexLogged, isTrue);
  });

  testWidgets('Enabled packs put canonical trackers on Today', (tester) async {
    // Tall viewport so the whole Today column builds — the tracker grid sits
    // below the fold at the default 800x600 test surface.
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore();

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // `base_symptoms` ships enabled, so its day-grain trackers should be on
    // Today straight from the bundled catalog with nothing toggled. These
    // tiles only exist if the asset catalog decoded and the pack resolved.
    expect(find.text('TRACKERS'), findsWidgets);
    for (final label in ['SPOTTING', 'SLEEP', 'WEIGHT', 'SEX']) {
      expect(find.text(label), findsWidgets, reason: '$label missing on Today');
    }

    // Turning the pack off should clear them again.
    await tester.tap(find.text('trackers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('on TODAY').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('today'));
    await tester.pumpAndSettle();

    expect(find.text('SLEEP'), findsNothing);
  });

  testWidgets('Today edit and gear route to real tabs', (tester) async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore();

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('EDIT'));
    await tester.pumpAndSettle();
    expect(find.text('TRACKER PACKS'), findsOneWidget);

    await tester.tap(find.text('today'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('CYCLE DEFAULTS'), findsOneWidget);
  });

  test('local store derives cycle from logged bleeding starts', () async {
    Clock.overrideNow(DateTime(2026, 5, 4));
    seedStore();

    final store = LocalPeriodStore();
    await store.load();

    store.setBleeding(DateTime(2026, 4, 6), BleedLevel.med);
    store.setBleeding(DateTime(2026, 4, 7), BleedLevel.light);
    store.setBleeding(DateTime(2026, 5, 4), BleedLevel.med);

    expect(store.cycleAnchor, DateTime(2026, 5, 4));
    expect(store.cycleLen, 28);
    expect(store.cycleStateFor(DateTime(2026, 5, 4)).cycleDay, 1);
  });

  test(
    'local store emits contract-shaped observations from daily logs',
    () async {
      Clock.overrideNow(DateTime(2026, 5, 4));
      SharedPreferences.setMockInitialValues({});
      addTearDown(() => Clock.overrideNow(null));

      final store = LocalPeriodStore();
      await store.load();

      store.setBleeding(DateTime(2026, 5, 4), BleedLevel.med);
      store.setSymptom(DateTime(2026, 5, 4), 'pelvic pain', Severity.moderate);
      store.setSymptom(DateTime(2026, 5, 4), 'anxiety', Severity.mild);
      store.setNumeric(DateTime(2026, 5, 4), 'sleep', 7.5);
      store.setMood(DateTime(2026, 5, 4), 'good');
      store.setBooleanValue(DateTime(2026, 5, 4), 'spotting', true);
      store.setEnumValue(DateTime(2026, 5, 4), 'cervical_mucus', 'egg_white');
      store.setTextValue(DateTime(2026, 5, 4), 'medication', 'magnesium');

      final observations = store.observations;
      expect(
        observations.map((o) => o.trackerCode),
        contains('period_bleeding'),
      );
      expect(observations.map((o) => o.trackerCode), contains('pelvic_pain'));
      expect(
        observations.map((o) => o.trackerCode),
        contains('anxiety_severity'),
      );
      expect(observations.map((o) => o.trackerCode), contains('sleep_hours'));
      expect(observations.map((o) => o.trackerCode), contains('mood'));
      expect(observations.map((o) => o.trackerCode), contains('spotting'));
      expect(
        observations.map((o) => o.trackerCode),
        contains('cervical_mucus'),
      );
      expect(observations.map((o) => o.trackerCode), contains('medication'));
      expect(observations.every((o) => o.source == 'user_entered'), isTrue);
    },
  );

  test('cycle model shrinks sparse history toward population prior', () {
    final state = fitCycleModel([
      const CycleLengthObservation(cycleIndex: 0, lengthDays: 35),
    ]);
    expect(state.posteriorMeanDays, greaterThan(29));
    expect(state.posteriorMeanDays, lessThan(35));

    final prediction = predictNextCycle(state);
    expect(prediction.p10LengthDays, lessThan(prediction.p50LengthDays));
    expect(prediction.p50LengthDays, lessThan(prediction.p90LengthDays));
    expect(prediction.predictiveSdDays, greaterThan(0));
  });

  test('cycle confidence follows predictive window and history floor', () {
    final starter = predictNextCycle(fitCycleModel([]));
    expect(
      confidenceLabelForPrediction(starter, cycleStartCount: 1),
      'starter',
    );

    final medium = predictNextCycle(
      fitCycleModel([
        const CycleLengthObservation(cycleIndex: 0, lengthDays: 28),
        const CycleLengthObservation(cycleIndex: 1, lengthDays: 29),
        const CycleLengthObservation(cycleIndex: 2, lengthDays: 28),
      ]),
    );
    expect(medium.p80WindowDays, lessThanOrEqualTo(12));
    expect(confidenceLabelForPrediction(medium, cycleStartCount: 4), 'medium');

    final high = CyclePrediction(
      expectedLengthDays: 28,
      p10LengthDays: 25,
      p50LengthDays: 28,
      p90LengthDays: 31,
      predictiveSdDays: 2.3,
      skippedTrackingProbability: 0,
      elapsedCycleDay: null,
    );
    expect(confidenceLabelForPrediction(high, cycleStartCount: 6), 'high');
  });

  test('cycle model adjusts likely skipped tracking cycle', () {
    final state = fitCycleModel([
      const CycleLengthObservation(cycleIndex: 0, lengthDays: 27),
      const CycleLengthObservation(cycleIndex: 1, lengthDays: 28),
      const CycleLengthObservation(cycleIndex: 2, lengthDays: 56),
    ]);
    expect(state.skipProbabilities.last, greaterThan(0.80));
    expect(state.adjustedLengths.last, lessThan(35));
    expect(state.posteriorMeanDays, lessThan(31));
  });

  testWidgets('Calendar phase scales with cycle length, not a fixed 28 days', (
    tester,
  ) async {
    // Regression: phase math was hardcoded to a 28-day cycle, so late-cycle
    // days on a long cycle were mislabelled "menstrual" and flow-tinted.
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore('{"setupComplete":true,"cycleLen":45,"flowLen":4}');

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('calendar'));
    await tester.pumpAndSettle();
    // anchor = may 2 (today may 5 is cycle day 4); may 31 is cycle day 30,
    // which on a 45-day cycle is luteal — not the menstrual it used to claim.
    await tester.tap(find.text('31').first);
    await tester.pumpAndSettle();

    // Pre-fix this day reported "menstrual phase" (cd 30 fell in the hardcoded
    // late-luteal-into-flow window of a 28-day model); it must now be luteal.
    expect(find.text('cycle day 30'), findsOneWidget);
    expect(find.text('luteal phase'), findsOneWidget);
  });

  test('symptom note persists with its symptom and clears with it', () async {
    // Regression: the symptom sheet's note field was silently discarded.
    Clock.overrideNow(DateTime(2026, 5, 4));
    seedStore();

    final store = LocalPeriodStore();
    await store.load();
    final day = DateTime(2026, 5, 4);

    store.setSymptom(day, 'cramps', Severity.moderate, 'left side, woke at 3am');
    expect(store.logFor(day).symptomNotes['cramps'], 'left side, woke at 3am');

    // The note must round-trip the contract-shaped observation export.
    final crampObs = store.observations.firstWhere(
      (o) => o.trackerCode == 'cramps',
    );
    expect(crampObs.note, 'left side, woke at 3am');

    // Clearing the symptom clears its note too — no orphaned notes.
    store.setSymptom(day, 'cramps', null);
    expect(store.logFor(day).symptomNotes.containsKey('cramps'), isFalse);
  });

  // ---- first-run setup ----

  testWidgets('first run shows setup instead of the tab shell', (tester) async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('your data stays here.'), findsOneWidget);
    expect(find.text('bleeding'), findsNothing);
    expect(find.text('calendar'), findsNothing);
  });

  testWidgets('a returning user never sees setup', (tester) async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore();

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('your data stays here.'), findsNothing);
    expect(find.text('bleeding'), findsOneWidget);
  });

  test('completeSetup stores the date and survives a reload', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    SharedPreferences.setMockInitialValues({});

    final first = LocalPeriodStore();
    await first.load();
    expect(first.setupComplete, isFalse);

    await first.completeSetup(
      lastPeriodStart: DateTime(2026, 5, 1),
      cycleLength: 32,
    );

    final second = LocalPeriodStore();
    await second.load();
    expect(second.setupComplete, isTrue);
    expect(second.cycleAnchor, DateTime(2026, 5, 1));
    expect(second.cycleLen, 32);
    expect(second.cycleDayFor(DateTime(2026, 5, 5)), 5);
  });

  test('skipping the date leaves the cycle genuinely unknown', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    SharedPreferences.setMockInitialValues({});

    final store = LocalPeriodStore();
    await store.load();
    await store.completeSetup(lastPeriodStart: null, cycleLength: null);

    expect(store.hasCycleAnchor, isFalse);
    expect(store.cycleAnchor, isNull);
    expect(store.cycleDayFor(DateTime(2026, 5, 5)), isNull);

    final state = store.cycleStateFor(DateTime(2026, 5, 5));
    expect(state.cycleDay, isNull);
    expect(state.nextStart, isNull);
    expect(state.nextMode, isNull);
    expect(state.avg, isNull);

    // And it stays unknown across a restart rather than quietly reverting to
    // the demo anchor.
    final reloaded = LocalPeriodStore();
    await reloaded.load();
    expect(reloaded.hasCycleAnchor, isFalse);
  });

  testWidgets('skipping the date shows no fabricated cycle day', (
    tester,
  ) async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore('{"setupComplete":true,"hasCycleAnchor":false}');

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('no cycle data yet'), findsOneWidget);
    expect(find.text('EST. WINDOW'), findsNothing);
    expect(find.textContaining('cycle day'), findsNothing);

    // The calendar must not tint phases or key colours it isn't showing.
    await tester.tap(find.text('calendar'));
    await tester.pumpAndSettle();
    expect(find.text('no cycle data yet'), findsOneWidget);
    expect(find.text('PHASES'), findsNothing);
    expect(find.text('predicted'), findsNothing);
  });

  test('logging a bleeding day recovers from an unknown anchor', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore('{"setupComplete":true,"hasCycleAnchor":false}');

    final store = LocalPeriodStore();
    await store.load();
    expect(store.hasCycleAnchor, isFalse);

    store.setBleeding(DateTime(2026, 5, 3), BleedLevel.med);

    expect(store.cycleAnchor, DateTime(2026, 5, 3));
    expect(store.cycleDayFor(DateTime(2026, 5, 5)), 3);
  });

  test('a blob without the flag is treated as an existing user', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    seedStore('{"cycleLen":30}');

    final store = LocalPeriodStore();
    await store.load();

    expect(store.setupComplete, isTrue);
    expect(store.cycleLen, 30);
    // Legacy blobs keep the old fallback anchor rather than going unknown.
    expect(store.hasCycleAnchor, isTrue);
  });

  test('a self-reported cycle length survives one logged start', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    SharedPreferences.setMockInitialValues({});

    final store = LocalPeriodStore();
    await store.load();
    await store.completeSetup(cycleLength: 33);

    store.setBleeding(DateTime(2026, 5, 2), BleedLevel.med);

    // One start gives no interval to fit, so the user's number stands.
    expect(store.cycleLen, 33);
  });

  test('resetting logs keeps setup but clears the anchor', () async {
    Clock.overrideNow(DateTime(2026, 5, 5));
    SharedPreferences.setMockInitialValues({});

    final store = LocalPeriodStore();
    await store.load();
    await store.completeSetup(lastPeriodStart: DateTime(2026, 5, 1));
    await store.resetDemoLogs();

    expect(store.setupComplete, isTrue);
    expect(store.hasCycleAnchor, isFalse);
  });

  testWidgets('walking setup end to end lands on Today with a real cycle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Clock.overrideNow(DateTime(2026, 5, 20));
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PeriodApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // Pick may 14, six days back.
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(find.text('thu, may 14'), findsOneWidget);
    expect(find.text('6 DAYS AGO'), findsOneWidget);

    await tester.tap(find.text('continue'));
    await tester.pumpAndSettle();
    expect(find.text('how long is your usual cycle?'), findsOneWidget);

    await tester.tap(find.text('continue'));
    await tester.pumpAndSettle();
    expect(find.text('four tabs.'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('done'));
    await tester.pumpAndSettle();

    // The shell, with a prediction derived from the date just entered.
    expect(find.text('wed, may 20'), findsOneWidget);
    expect(find.text('EST. WINDOW'), findsOneWidget);
    expect(find.text('no cycle data yet'), findsNothing);
  });
}
