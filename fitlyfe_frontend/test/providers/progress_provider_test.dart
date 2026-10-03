import 'package:fitlyfe_frontend/models/progress.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProgressProvider provider;

  setUp(() => provider = ProgressProvider());
  tearDown(() => provider.dispose());

  bool isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  group('health sync', () {
    test("writes today's steps and active minutes", () {
      provider.syncHealthData(9876, 42);

      final today = provider.progressData
          .where((d) => isToday(d.date))
          .toList();
      expect(today, hasLength(1));
      expect(today.single.steps, 9876);
      expect(today.single.workoutTime, const Duration(minutes: 42));
    });

    test('syncing again updates today instead of adding a day', () {
      provider.syncHealthData(100, 1);
      final days = provider.progressData.length;

      provider.syncHealthData(200, 2);

      expect(provider.progressData.length, days);
      expect(
        provider.progressData.firstWhere((d) => isToday(d.date)).steps,
        200,
      );
    });
  });

  group('goals', () {
    test('toggling a goal completes it and announces it once', () async {
      final goal = provider.goals.firstWhere((g) => !g.isCompleted);
      final messages = <String>[];
      final sub = provider.completionStream.listen(messages.add);

      provider.toggleGoalStatus(goal.id);
      await Future<void>.delayed(Duration.zero);

      final updated = provider.goals.firstWhere((g) => g.id == goal.id);
      expect(updated.isCompleted, isTrue);
      expect(updated.currentValue, goal.targetValue);
      expect(messages, ['Good job on completing your goal: ${goal.title}!']);

      provider.toggleGoalStatus(goal.id);
      await Future<void>.delayed(Duration.zero);
      expect(
        provider.goals.firstWhere((g) => g.id == goal.id).isCompleted,
        isFalse,
      );
      expect(messages, hasLength(1), reason: 'un-completing is not announced');
      await sub.cancel();
    });

    test('progress past the target completes a goal', () async {
      final goal = provider.goals.firstWhere(
        (g) => !g.isCompleted && g.targetValue > 1,
      );
      final messages = <String>[];
      final sub = provider.completionStream.listen(messages.add);

      provider.updateGoal(goal.id, goal.targetValue / 2);
      expect(
        provider.goals.firstWhere((g) => g.id == goal.id).isCompleted,
        isFalse,
      );

      provider.updateGoal(goal.id, goal.targetValue);
      await Future<void>.delayed(Duration.zero);
      expect(
        provider.goals.firstWhere((g) => g.id == goal.id).isCompleted,
        isTrue,
      );
      expect(messages.single, contains(goal.title));
      await sub.cancel();
    });

    test('unknown goal ids are ignored', () {
      final before = provider.goals.map((g) => g.isCompleted).toList();
      provider.toggleGoalStatus('nope');
      provider.updateGoal('nope', 10);
      expect(provider.goals.map((g) => g.isCompleted).toList(), before);
    });
  });

  group('achievements', () {
    test('unlocking announces the achievement only the first time', () async {
      final messages = <String>[];
      final sub = provider.completionStream.listen(messages.add);

      provider.unlockAchievement('b1');
      provider.unlockAchievement('b1');
      await Future<void>.delayed(Duration.zero);

      final achievement = provider.achievements.firstWhere((a) => a.id == 'b1');
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.unlockedDate, isNotNull);
      expect(messages, hasLength(1));
      expect(messages.single, contains(achievement.title));
      await sub.cancel();
    });
  });

  group('totals', () {
    test('weight lost compares the first and last entries by date', () {
      final fresh = ProgressProvider();
      fresh.progressData.clear();
      final today = DateTime.now();
      // Added out of order on purpose
      fresh.addProgressData(
        ProgressData(date: today, caloriesBurned: 0, weight: 78),
      );
      fresh.addProgressData(
        ProgressData(
          date: today.subtract(const Duration(days: 10)),
          caloriesBurned: 0,
          weight: 80,
        ),
      );

      expect(fresh.totalWeightLost, 2);
      fresh.dispose();
    });

    test('weight gained is not reported as a loss', () {
      final fresh = ProgressProvider();
      fresh.progressData.clear();
      final today = DateTime.now();
      fresh.addProgressData(
        ProgressData(
          date: today.subtract(const Duration(days: 3)),
          caloriesBurned: 0,
          weight: 70,
        ),
      );
      fresh.addProgressData(
        ProgressData(date: today, caloriesBurned: 0, weight: 72),
      );

      expect(fresh.totalWeightLost, 0);
      fresh.dispose();
    });
  });
}
