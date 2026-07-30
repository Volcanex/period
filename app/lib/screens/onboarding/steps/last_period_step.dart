import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../onboarding_scaffold.dart';
import '../widgets/onboarding_buttons.dart';
import '../widgets/onboarding_date_grid.dart';

const _monthNames = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class LastPeriodStep extends StatelessWidget {
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const LastPeriodStep({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      eyebrow: 'step 2 / 4',
      title: 'When did your last period start?',
      body: 'Pick the first day you bled. A rough guess is fine.',
      actions: Column(
        children: [
          OnboardingPrimaryButton(
            label: 'Continue',
            enabled: selected != null,
            onPressed: onNext,
          ),
          OnboardingTextLink(label: "I don't know", onTap: onSkip),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingDateGrid(
            today: today,
            selected: selected,
            onSelected: onSelected,
          ),
          const SizedBox(height: 18),
          // Fixed height so the grid doesn't jump when a date is picked.
          SizedBox(height: 44, child: Center(child: _readout())),
        ],
      ),
    );
  }

  Widget _readout() {
    final date = selected;
    if (date == null) {
      return Text(
        'NOT SET',
        style: Type.mono(
          size: 11,
          color: Tokens.graphite2,
          letterSpacingEm: 0.08,
        ),
      );
    }
    final days = today.difference(date).inDays;
    final ago = switch (days) {
      0 => 'TODAY',
      1 => 'YESTERDAY',
      _ => '$days DAYS AGO',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_dayNames[date.weekday]}, ${_monthNames[date.month]} ${date.day}',
          style: Type.display(size: 17, weight: Tokens.fwMedium, height: 1.1),
        ),
        const SizedBox(height: 4),
        Text(
          ago,
          style: Type.mono(
            size: 10,
            color: Tokens.graphite2,
            letterSpacingEm: 0.08,
          ),
        ),
      ],
    );
  }
}
