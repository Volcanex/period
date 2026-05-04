import 'package:flutter/material.dart';

import 'data/models.dart';
import 'screens/shared/stub_screen.dart';
import 'screens/shared/tab_bar.dart';
import 'screens/today/today_screen.dart';
import 'theme/tokens.dart';

/// Holds the cross-tab state (mirrors `App` in `main.jsx`) and routes between
/// Today and the stub screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab tab = AppTab.today;

  // Tweaks that the design's tweaks panel surfaces. We hardcode mid-cycle for
  // now; a settings/dev-tools surface can flip these later.
  String cycleStateKey = 'midcycle';
  bool showMiniRing = true;
  bool compact = false;
  String pinnedSet = 'default';

  // Logged state.
  BleedLevel? bleeding;
  Map<String, Severity> symptoms = {
    'cramps': Severity.mild,
    'low energy': Severity.moderate,
  };
  String? mood = 'neutral';
  Map<String, double> numericValues = {'bbt': 97.65};
  String note = '';

  List<String> get _pinned {
    return switch (pinnedSet) {
      'minimal' => const ['bbt'],
      'wide' => const ['bbt', 'sleep', 'weight', 'cervical'],
      _ => const ['bbt', 'sleep'],
    };
  }

  void _setSymptom(String s, Severity? sev) {
    setState(() {
      if (sev == null) {
        symptoms.remove(s);
      } else {
        symptoms[s] = sev;
      }
    });
  }

  void _setNumeric(String id, double v) {
    setState(() => numericValues[id] = v);
  }

  Widget _screen() {
    final cs = cycleStates[cycleStateKey]!;
    return switch (tab) {
      AppTab.today => TodayScreen(
          cycleState: cs,
          pinnedTrackers: _pinned,
          showMiniRing: showMiniRing,
          compact: compact,
          bleeding: bleeding,
          onBleedingChanged: (b) => setState(() => bleeding = b),
          symptoms: symptoms,
          onSymptomChanged: _setSymptom,
          mood: mood,
          onMoodChanged: (m) => setState(() => mood = m),
          numericValues: numericValues,
          onNumericChanged: _setNumeric,
          note: note,
          onNoteChanged: (n) => setState(() => note = n),
        ),
      AppTab.calendar => const StubScreen(
          title: 'calendar',
          eyebrow: 'next',
          body: 'month and cycle calendar with phase tints. comes after today.',
        ),
      AppTab.insights => const StubScreen(
          title: 'insights',
          eyebrow: 'next',
          body: 'cycle length, flow length, and symptom histograms. on-device only.',
        ),
      AppTab.trackers => const StubScreen(
          title: 'trackers',
          eyebrow: 'next',
          body: 'pin, unpin, and reorder trackers. tracker packs (pcos, endo, pms/pmdd, perimenopause, contraception) layer on without changing the model.',
        ),
      AppTab.exports => const StubScreen(
          title: 'export',
          eyebrow: 'next',
          body: 'a portable, validatable bundle you own. import on another device or share with a clinician.',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tokens.base,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 64,
            child: _screen(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomTabBar(
              current: tab,
              onChanged: (t) => setState(() => tab = t),
            ),
          ),
        ],
      ),
    );
  }
}
