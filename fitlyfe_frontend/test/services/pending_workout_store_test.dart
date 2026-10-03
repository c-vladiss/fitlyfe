import 'package:fitlyfe_frontend/services/pending_workout_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = SharedPreferencesPendingWorkoutStore();

  test('starts empty', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await store.load(), isEmpty);
  });

  test('round-trips pending workouts', () async {
    SharedPreferences.setMockInitialValues({});
    final pending = [
      {
        'clientId': 'a',
        'startedAt': '2025-05-01T08:00:00.000Z',
        'exercises': [
          {
            'name': 'Squat',
            'sets': [
              {'reps': 5, 'weightKg': 100.0},
            ],
          },
        ],
      },
    ];

    await store.save(pending);

    expect(await store.load(), pending);
  });

  test('saving an empty list clears the stored value', () async {
    SharedPreferences.setMockInitialValues({});
    await store.save([
      {'clientId': 'a'},
    ]);

    await store.save([]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    expect(await store.load(), isEmpty);
  });

  test('ignores corrupt data instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'pending_workout_sessions': '{not json',
    });
    expect(await store.load(), isEmpty);
  });
}
