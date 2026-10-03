import 'package:fitlyfe_frontend/screens/main_screen.dart';
import 'package:fitlyfe_frontend/widgets/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  bool isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Finder notificationText(String text) => find.descendant(
    of: find.byType(TopNotification),
    matching: find.textContaining(text),
  );

  /// MainScreen triggers the "First Step" achievement 2 s after opening and a
  /// notification stays up for 4 s; run the clock past both.
  Future<void> letNotificationsFinish(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('bottom navigation switches between the main tabs', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester, const MainScreen());
    await tester.pump();

    final tabs = {
      Icons.local_fire_department_outlined: 1,
      Icons.fitness_center_outlined: 2,
      Icons.bar_chart_outlined: 3,
      Icons.auto_awesome_outlined: 4,
      Icons.home_outlined: 0,
    };
    for (final MapEntry(key: icon, value: index) in tabs.entries) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pump();
      expect(app.appState.selectedPageIndex, index, reason: '$icon');
    }
    await letNotificationsFinish(tester);
  });

  testWidgets(
    'opening the app records the streak and announces the first achievement',
    (tester) async {
      final app = TestApp();
      await app.pump(tester, const MainScreen());

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 600));

      expect(app.appState.currentUser.streakCount, 1);
      expect(
        app.progress.achievements.firstWhere((a) => a.id == 'b1').isUnlocked,
        isTrue,
      );
      expect(notificationText('First Step'), findsOneWidget);

      await letNotificationsFinish(tester);
      expect(find.byType(TopNotification), findsNothing);
    },
  );

  testWidgets('notifications are queued and shown one at a time', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester, const MainScreen());
    await tester.pump(const Duration(seconds: 2)); // first achievement
    final goals = app.progress.goals
        .where((g) => !g.isCompleted)
        .take(2)
        .toList();

    app.progress.toggleGoalStatus(goals[0].id);
    app.progress.toggleGoalStatus(goals[1].id);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TopNotification), findsOneWidget);
    expect(notificationText('First Step'), findsOneWidget);

    for (final goal in goals) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TopNotification), findsOneWidget);
      expect(notificationText(goal.title), findsOneWidget);
    }
    await letNotificationsFinish(tester);
    expect(find.byType(TopNotification), findsNothing);
  });

  testWidgets("authorized health data is copied into today's progress", (
    tester,
  ) async {
    final app = TestApp(
      health: FakeHealthProvider(
        authorized: true,
        fakeSteps: 4321,
        fakeActiveMinutes: 37,
      ),
    );
    await app.pump(tester, const MainScreen());
    await tester.pump();

    final today = app.progress.progressData.firstWhere((d) => isToday(d.date));
    expect(today.steps, 4321);
    expect(today.workoutTime, const Duration(minutes: 37));

    // Later updates from the health service are picked up too
    app.health.fakeSteps = 5000;
    app.health.notifyListeners();
    expect(
      app.progress.progressData.firstWhere((d) => isToday(d.date)).steps,
      5000,
    );
    await letNotificationsFinish(tester);
  });

  testWidgets('stops listening to health updates once closed', (tester) async {
    final app = TestApp(
      health: FakeHealthProvider(authorized: true, fakeSteps: 1),
    );
    await app.pump(tester, const MainScreen());
    await letNotificationsFinish(tester);

    await tester.pumpWidget(const SizedBox());
    app.health.fakeSteps = 999;
    app.health.notifyListeners();

    expect(
      app.progress.progressData.firstWhere((d) => isToday(d.date)).steps,
      1,
    );
  });
}
