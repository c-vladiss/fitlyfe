import 'package:fitlyfe_frontend/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_app.dart';

void main() {
  late TestApp app;

  setUp(() {
    app = TestApp();
    when(() => app.graphQL.completeOnboarding()).thenAnswer((_) async => true);
  });

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('walks through every step and saves the answers', (tester) async {
    await app.pump(tester, const OnboardingScreen());
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alex');
    await tapContinue(tester);

    expect(find.text('When were you born?'), findsOneWidget);
    await tapContinue(tester);
    expect(find.text('How tall are you?'), findsOneWidget);
    await tapContinue(tester);
    expect(find.text('What is your current weight?'), findsOneWidget);
    await tapContinue(tester); // meals
    await tapContinue(tester); // goal

    expect(find.text('Finally, what is your main goal?'), findsOneWidget);
    await tester.tap(find.text('Lose Weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final user = app.appState.currentUser;
    expect(user.name, 'Alex');
    expect(user.goal, 'lose_weight');
    expect(app.appState.requiresOnboarding, isFalse);
    verify(() => app.graphQL.completeOnboarding()).called(1);
    // The meal template chosen during onboarding becomes the default
    expect(app.nutrition.getMealsForDate(DateTime.now()).map((m) => m.name), [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snacks',
    ]);
  });

  testWidgets('the chosen goal picks matching workout routines', (
    tester,
  ) async {
    await app.pump(tester, const OnboardingScreen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tapContinue(tester);
    }

    await tester.tap(find.text('Build Muscle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(app.appState.currentUser.goal, 'build_muscle');
    expect(app.workouts.routines.first.name, 'Push Day (Chest/Triceps)');
  });

  testWidgets('an empty name falls back to a default', (tester) async {
    await app.pump(tester, const OnboardingScreen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tapContinue(tester);
    }
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(app.appState.currentUser.name, 'Fitness User');
  });
}
