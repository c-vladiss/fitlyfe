import 'package:fitlyfe_frontend/models/progress.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProgressProvider provider;

  setUp(() => provider = ProgressProvider());
  tearDown(() => provider.dispose());

  DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

  test('starts without invented history', () {
    expect(provider.progressData, isEmpty);
    expect(provider.totalSteps, 0);
    expect(provider.totalWorkoutHours, 0);
    expect(provider.totalWeightLost, 0);
    expect(provider.averageCaloriesBurned, 0);
  });

  test('goals start with no progress', () {
    expect(provider.goals, isNotEmpty);
    expect(provider.goals.every((g) => g.currentValue == 0 && !g.isCompleted), isTrue);
  });

  test('health sync creates today and then updates it', () {
    provider.syncHealthData(4200, 35);
    provider.syncHealthData(5000, 40);

    expect(provider.progressData, hasLength(1));
    expect(provider.totalSteps, 5000);
    expect(provider.last7DaysData.single.workoutTime, const Duration(minutes: 40));
  });

  test('last 7 days covers today and the 6 days before', () {
    for (final days in [0, 6, 7, 30]) {
      provider.addProgressData(ProgressData(date: daysAgo(days), caloriesBurned: days.toDouble()));
    }

    expect(provider.last7DaysData.map((d) => d.caloriesBurned), [6, 0]);
  });

  test('average calories ignores days without a value', () {
    provider.addProgressData(ProgressData(date: daysAgo(2), caloriesBurned: 300));
    provider.addProgressData(ProgressData(date: daysAgo(1), caloriesBurned: 500));
    provider.syncHealthData(1000, 10); // today, no calorie data

    expect(provider.averageCaloriesBurned, 400);
  });
}
