// Basic smoke test for the Today screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:period_app/main.dart';

void main() {
  testWidgets('Today screen renders with date and bleeding card', (tester) async {
    await tester.pumpWidget(const PeriodApp());
    // GoogleFonts pulls fonts at runtime; pump a couple of frames so async
    // font loads settle without making the test brittle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('today'), findsWidgets);
    expect(find.text('bleeding'), findsOneWidget);
    expect(find.text('mon, may 4'), findsOneWidget);
  });
}
