import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../shared/number_stepper.dart';
import '../onboarding_scaffold.dart';
import '../widgets/onboarding_buttons.dart';

class CycleLengthStep extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const CycleLengthStep({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      eyebrow: 'step 3 / 4',
      title: 'How long is your usual cycle?',
      body:
          'Count from the first day of one period to the day before the next. '
          'Most cycles are 25 to 32 days.',
      actions: Column(
        children: [
          OnboardingPrimaryButton(label: 'Continue', onPressed: onNext),
          OnboardingTextLink(label: "I'm not sure", onTap: onSkip),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: NumberStepper(
              value: value,
              min: 21,
              max: 45,
              unit: 'd',
              large: true,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '21 TO 45 DAYS',
            style: Type.mono(
              size: 10,
              color: Tokens.graphite2,
              letterSpacingEm: 0.08,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "We'll start at 28 and adjust as you log.",
            textAlign: TextAlign.center,
            style: Type.body(size: 13, color: Tokens.graphite2, height: 1.45),
          ),
        ],
      ),
    );
  }
}
