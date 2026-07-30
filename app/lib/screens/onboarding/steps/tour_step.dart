import 'package:flutter/material.dart';

import '../../../theme/icons.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../onboarding_scaffold.dart';
import '../widgets/onboarding_buttons.dart';
import '../widgets/step_dots.dart';

class _Card {
  final IconData icon;
  final String name;
  final String text;
  const _Card(this.icon, this.name, this.text);
}

// Four cards for five tabs — settings needs no tour, and the privacy screen
// already says everything is changeable there.
const _cards = [
  _Card(
    Ph.circle,
    'Today',
    "Log what's happening today — bleeding, mood, symptoms, a note. "
        'Tap anything to change it.',
  ),
  _Card(
    Ph.calendarBlank,
    'Calendar',
    'Your months at a glance. Solid days are what you logged. '
        'Dashed days are estimates.',
  ),
  _Card(
    Ph.chartLine,
    'Insights',
    'Patterns drawn from your own logs. These are patterns, not diagnoses.',
  ),
  _Card(
    Ph.listChecks,
    'Trackers',
    'Turn on only what you want to track. You can change this any time.',
  ),
];

class TourStep extends StatefulWidget {
  final VoidCallback onDone;

  const TourStep({super.key, required this.onDone});

  @override
  State<TourStep> createState() => _TourStepState();
}

class _TourStepState extends State<TourStep> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _cards.length - 1) {
      widget.onDone();
      return;
    }
    _pages.animateToPage(
      _page + 1,
      duration: Tokens.durBase,
      curve: Tokens.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _cards.length - 1;
    return OnboardingScaffold(
      eyebrow: 'step 4 / 4',
      title: 'Four tabs.',
      trailing: OnboardingTextLink(
        label: 'skip',
        mono: true,
        onTap: widget.onDone,
      ),
      actions: OnboardingPrimaryButton(
        label: last ? 'Done' : 'Next',
        onPressed: _next,
      ),
      child: Column(
        children: [
          // Fixed height so the dots hold still between cards.
          SizedBox(
            height: 220,
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _page = i),
              children: [for (final c in _cards) _TourCard(card: c)],
            ),
          ),
          const SizedBox(height: 18),
          StepDots(count: _cards.length, current: _page),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final _Card card;

  const _TourCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(card.icon, size: 24, color: Tokens.ink),
          const SizedBox(height: 12),
          Text(
            card.name,
            style: Type.display(
              size: 22,
              weight: Tokens.fwMedium,
              height: 1.1,
              letterSpacingEm: -0.01,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.text,
            style: Type.body(size: 14, color: Tokens.graphite2, height: 1.5),
          ),
        ],
      ),
    );
  }
}
