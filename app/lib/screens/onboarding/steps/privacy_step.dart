import 'package:flutter/material.dart';

import '../../../theme/icons.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../onboarding_scaffold.dart';
import '../widgets/onboarding_buttons.dart';
import '../widgets/point_row.dart';

class PrivacyStep extends StatelessWidget {
  final VoidCallback onNext;

  const PrivacyStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      eyebrow: 'Sequence',
      title: 'Your data stays here.',
      body: 'Sequence runs entirely on this device.',
      actions: Column(
        children: [
          OnboardingPrimaryButton(label: 'Start', onPressed: onNext),
          const SizedBox(height: 10),
          Text(
            'TAKES ABOUT A MINUTE · CHANGE ANYTHING LATER IN SETTINGS',
            textAlign: TextAlign.center,
            style: Type.mono(
              size: 9,
              color: Tokens.graphite2,
              letterSpacingEm: 0.08,
              height: 1.4,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PointRow(
            icon: Ph.lockSimple,
            text: 'Nothing is uploaded. There is no server.',
          ),
          const PointRow(
            icon: Ph.deviceMobile,
            text: 'Your logs live on this phone.',
          ),
          const PointRow(
            icon: Ph.userCircle,
            text: 'No account. No email. No password.',
          ),
          const PointRow(
            icon: Ph.code,
            text: 'The code is open source. You can read it.',
          ),
          const SizedBox(height: 24),
          Text(
            '[ ON-DEVICE · NO ACCOUNT · NO CLOUD ]',
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
