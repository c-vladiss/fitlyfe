import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WorkoutProvider provider;

  setUp(() => provider = WorkoutProvider());

  const expectedFirstRoutine = {
    'lose_weight': 'Fat Burning HIIT',
    'build_muscle': 'Push Day (Chest/Triceps)',
    'improve_endurance': 'Stamina Power Circuit',
    'stay_fit': 'Balanced Athlete',
  };

  for (final MapEntry(key: goal, value: routine)
      in expectedFirstRoutine.entries) {
    test('$goal gets its own routines', () {
      provider.initializeWorkoutsForGoal(goal);
      expect(provider.routines.first.name, routine);
      expect(provider.currentRoutine, provider.routines.first);
    });
  }

  test('labels stored by older versions still match', () {
    provider.initializeWorkoutsForGoal('Lose Weight');
    expect(provider.routines.first.name, 'Fat Burning HIIT');

    provider.initializeWorkoutsForGoal('Improve Endurance');
    expect(provider.routines.first.name, 'Stamina Power Circuit');
  });

  test('an unknown goal gets general fitness routines', () {
    provider.initializeWorkoutsForGoal('something else');
    expect(provider.routines.first.name, 'Balanced Athlete');
  });

  test('changing goal replaces the previous routines', () {
    provider.initializeWorkoutsForGoal('lose_weight');
    provider.initializeWorkoutsForGoal('build_muscle');
    expect(
      provider.routines.map((r) => r.name),
      isNot(contains('Fat Burning HIIT')),
    );
  });
}
