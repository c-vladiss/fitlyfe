import 'package:fitlyfe_frontend/screens/goals_page.dart';
import 'package:fitlyfe_frontend/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'changing the primary goal updates the profile and the workout plan',
    (tester) async {
      final app = TestApp();
      app.appState.updateUserProfile(goal: 'stay_fit');
      await app.pump(tester, const Scaffold(body: ProfilePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primary Goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Improve Endurance').last);
      await tester.pumpAndSettle();

      expect(app.appState.currentUser.goal, 'improve_endurance');
      expect(app.workouts.routines.first.name, 'Stamina Power Circuit');
      expect(
        find.text('Improve Endurance'),
        findsOneWidget,
        reason: 'profile shows the new goal',
      );
    },
  );

  testWidgets('ticking a goal on the goals page completes it', (tester) async {
    final app = TestApp();
    await app.pump(tester, const GoalsPage());
    await tester.pumpAndSettle();
    final goal = app.progress.goals.firstWhere((g) => !g.isCompleted);

    await tester.tap(find.byKey(ValueKey('goal-check-${goal.id}')));
    await tester.pumpAndSettle();

    expect(
      app.progress.goals.firstWhere((g) => g.id == goal.id).isCompleted,
      isTrue,
    );
  });
}
