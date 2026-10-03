import 'package:fitlyfe_frontend/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('shows tips for the user\'s goal, whichever way it is stored', (
    tester,
  ) async {
    for (final goal in ['lose_weight', 'Lose Weight']) {
      final app = TestApp();
      app.appState.updateUserProfile(goal: goal);
      await app.pump(tester, const HomePage());
      await tester.pumpAndSettle();

      expect(
        find.text('Maintain a slight calorie deficit (200-500 kcal)'),
        findsOneWidget,
        reason: goal,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('asks to connect health data until authorized', (tester) async {
    final app = TestApp();
    await app.pump(tester, const HomePage());
    await tester.pumpAndSettle();

    expect(find.text('Connect to Health Services'), findsOneWidget);
    await tester.tap(find.text('CONNECT'));
    await tester.pumpAndSettle();

    expect(app.health.authorizationRequests, 1);
    expect(find.text('Connect to Health Services'), findsNothing);
  });
}
