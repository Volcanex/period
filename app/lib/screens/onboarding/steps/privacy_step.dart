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
      eyebrow: 'period',
      title: 'your data stays here.',
      body: 'period runs entirely on this device.',
      actions: Column(
        children: [
          OnboardingPrimaryButton(label: 'start', onPressed: onNext),
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
            text: 'nothing is uploaded. there is no server.',
          ),
          const PointRow(
            icon: Ph.deviceMobile,
            text: 'your logs live on this phone.',
          ),
          const PointRow(
            icon: Ph.userCircle,
            text: 'no account. no email. no password.',
          ),
          const PointRow(
            icon: Ph.code,
            text: 'the code is open source. you can read it.',
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
