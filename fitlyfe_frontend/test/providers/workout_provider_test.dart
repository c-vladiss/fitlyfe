import 'dart:async';

import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/services/pending_workout_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

final _routine = WorkoutRoutine(
  id: 'r1',
  name: 'Push Day',
  estimatedDuration: const Duration(minutes: 45),
  exercises: [
    Exercise(id: 'bench', name: 'Bench Press', sets: []),
    Exercise(id: 'dips', name: 'Dips', sets: []),
  ],
);

void main() {
  late MockGraphQLService graphQL;
  late InMemoryPendingWorkoutStore store;
  late WorkoutProvider provider;

  setUpAll(() {
    registerFallbackValue(
      Input$LogWorkoutSessionInput(startedAt: '', endedAt: '', exercises: []),
    );
  });

  setUp(() {
    graphQL = MockGraphQLService();
    store = InMemoryPendingWorkoutStore();
    provider = WorkoutProvider(graphQLService: graphQL, pendingStore: store);
  });

  /// Makes logWorkoutSession echo back a saved session for whatever it receives.
  void backendAcceptsWorkouts() {
    when(() => graphQL.logWorkoutSession(any())).thenAnswer((invocation) async {
      final input =
          invocation.positionalArguments.first as Input$LogWorkoutSessionInput;
      return TestData.workoutSession(
        id: 'server-${input.clientId}',
        startedAt: input.startedAt,
        endedAt: input.endedAt,
        workoutType: input.workoutType,
        exercises: [
          for (final (i, e) in input.exercises.indexed)
            TestData.workoutExercise(
              id: 'server-${input.clientId}-$i',
              name: e.name,
              orderIndex: i,
              sets: [for (final s in e.sets) (s.reps, s.weightKg)],
            ),
        ],
      );
    });
  }

  void logBenchSets() {
    provider.startSession(_routine);
    provider.addSetToExercise('bench', 10, 60);
    provider.addSetToExercise('bench', 8, 70);
  }

  group('active session', () {
    test('startSession copies the routine exercises without sets', () {
      provider.startSession(_routine);

      final session = provider.activeSession!;
      expect(session.routineName, 'Push Day');
      expect(session.exercises.map((e) => e.name), ['Bench Press', 'Dips']);
      expect(session.totalSets, 0);
    });

    test('sets can be added to and removed from an exercise', () {
      logBenchSets();
      final bench = provider.activeSession!.exercises.first;
      expect(bench.sets.map((s) => (s.reps, s.weight)), [
        (10, 60.0),
        (8, 70.0),
      ]);

      provider.removeSetFromExercise('bench', bench.sets.first.id);

      expect(provider.activeSession!.exercises.first.sets.map((s) => s.reps), [
        8,
      ]);
    });

    test('addExerciseToSession appends a new exercise', () {
      provider.startSession(_routine);
      provider.addExerciseToSession('Cable Fly');

      final exercises = provider.activeSession!.exercises;
      expect(exercises.last.name, 'Cable Fly');
      expect(exercises.map((e) => e.id).toSet().length, exercises.length);
    });

    test('discardSession drops the session without saving', () async {
      logBenchSets();
      provider.discardSession();

      expect(provider.activeSession, isNull);
      verifyNever(() => graphQL.logWorkoutSession(any()));
    });
  });

  group('endSession', () {
    test('saves only exercises that have sets', () async {
      backendAcceptsWorkouts();
      logBenchSets();
      final localId = provider.activeSession!.id;

      final result = await provider.endSession();

      expect(result, WorkoutSaveResult.saved);
      final input =
          verify(() => graphQL.logWorkoutSession(captureAny())).captured.single
              as Input$LogWorkoutSessionInput;
      expect(input.clientId, localId);
      expect(input.workoutType, 'Push Day');
      expect(input.exercises.map((e) => e.name), ['Bench Press']);
      expect(input.exercises.single.sets.map((s) => (s.reps, s.weightKg)), [
        (10, 60.0),
        (8, 70.0),
      ]);
      // Timestamps are sent in UTC
      expect(input.startedAt, endsWith('Z'));
      expect(input.endedAt, endsWith('Z'));
      expect(
        DateTime.parse(input.endedAt).isBefore(DateTime.parse(input.startedAt)),
        isFalse,
      );
    });

    test(
      'a saved session appears in the history and nothing stays pending',
      () async {
        backendAcceptsWorkouts();
        logBenchSets();

        await provider.endSession();

        expect(provider.activeSession, isNull);
        expect(provider.pendingCount, 0);
        expect(store.pending, isEmpty);
        expect(provider.sessions.single.isSynced, isTrue);
        expect(provider.sessions.single.id, startsWith('server-'));
        expect(provider.sessions.single.totalSets, 2);
      },
    );

    test('a session without any sets is not saved', () async {
      provider.startSession(_routine);

      final result = await provider.endSession();

      expect(result, WorkoutSaveResult.empty);
      expect(provider.activeSession, isNull);
      expect(provider.sessions, isEmpty);
      verifyNever(() => graphQL.logWorkoutSession(any()));
    });

    test('keeps the session on the device when saving fails', () async {
      when(
        () => graphQL.logWorkoutSession(any()),
      ).thenThrow(const BackendNetworkException('offline'));
      logBenchSets();
      final localId = provider.activeSession!.id;

      final result = await provider.endSession();

      expect(result, WorkoutSaveResult.pending);
      expect(provider.pendingCount, 1);
      expect(store.pending.single['clientId'], localId);
      final session = provider.sessions.single;
      expect(session.isSynced, isFalse);
      expect(session.id, localId);
      expect(session.exercises.single.name, 'Bench Press');
      expect(session.totalSets, 2);
      expect(provider.error, contains('offline'));
    });
  });

  group('syncing pending sessions', () {
    test(
      'a pending session is retried with the same clientId after a restart',
      () async {
        when(
          () => graphQL.logWorkoutSession(any()),
        ).thenThrow(const BackendNetworkException('offline'));
        logBenchSets();
        final localId = provider.activeSession!.id;
        await provider.endSession();

        // App restarts with the same device storage and the network is back
        final restarted = WorkoutProvider(
          graphQLService: graphQL,
          pendingStore: store,
        );
        backendAcceptsWorkouts();
        when(() => graphQL.getWorkoutSessions()).thenAnswer((_) async => []);

        await restarted.loadSessions();

        final retried =
            verify(() => graphQL.logWorkoutSession(captureAny())).captured.last
                as Input$LogWorkoutSessionInput;
        expect(retried.clientId, localId);
        expect(restarted.pendingCount, 0);
        expect(store.pending, isEmpty);
      },
    );

    test('uploads oldest first and stops at the first failure', () async {
      store = InMemoryPendingWorkoutStore([
        _pendingInput('first', '2025-05-01T08:00:00.000Z'),
        _pendingInput('second', '2025-05-02T08:00:00.000Z'),
        _pendingInput('third', '2025-05-03T08:00:00.000Z'),
      ]);
      provider = WorkoutProvider(graphQLService: graphQL, pendingStore: store);
      final attempted = <String?>[];
      when(() => graphQL.logWorkoutSession(any())).thenAnswer((
        invocation,
      ) async {
        final input =
            invocation.positionalArguments.first
                as Input$LogWorkoutSessionInput;
        attempted.add(input.clientId);
        if (input.clientId == 'second') {
          throw const BackendNetworkException('offline');
        }
        return TestData.workoutSession(id: 'server-${input.clientId}');
      });

      await provider.syncSessions();

      expect(attempted, ['first', 'second']);
      expect(store.pending.map((p) => p['clientId']), ['second', 'third']);
      expect(provider.pendingCount, 2);
    });

    test('concurrent syncs upload each session only once', () async {
      store = InMemoryPendingWorkoutStore([
        _pendingInput('only', '2025-05-01T08:00:00.000Z'),
      ]);
      provider = WorkoutProvider(graphQLService: graphQL, pendingStore: store);
      final response = Completer<WorkoutSessionResult>();
      when(
        () => graphQL.logWorkoutSession(any()),
      ).thenAnswer((_) => response.future);

      final first = provider.syncSessions();
      final second = provider.syncSessions();
      response.complete(TestData.workoutSession(id: 'server-only'));
      await Future.wait([first, second]);

      verify(() => graphQL.logWorkoutSession(any())).called(1);
      expect(provider.pendingCount, 0);
    });
  });

  group('loadSessions', () {
    test('maps backend sessions to local time, newest first', () async {
      when(() => graphQL.getWorkoutSessions()).thenAnswer(
        (_) async => [
          TestData.workoutSession(id: 'older', startedAt: '2025-05-01T08:00Z'),
          TestData.workoutSession(
            id: 'newer',
            startedAt: '2025-05-03T08:00Z',
            exercises: [
              TestData.workoutExercise(
                id: 'plank',
                name: 'Plank',
                // Timed sets have no reps
                sets: [(null, null)],
              ),
            ],
          ),
        ],
      );

      await provider.loadSessions();

      expect(provider.sessions.map((s) => s.id), ['newer', 'older']);
      final newer = provider.sessions.first;
      expect(newer.startTime, DateTime.utc(2025, 5, 3, 8).toLocal());
      expect(newer.startTime.isUtc, isFalse);
      expect(newer.exercises.single.sets.single.reps, 0);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test(
      'records the error and keeps the old history when loading fails',
      () async {
        when(
          () => graphQL.getWorkoutSessions(),
        ).thenAnswer((_) async => [TestData.workoutSession(id: 'kept')]);
        await provider.loadSessions();

        when(
          () => graphQL.getWorkoutSessions(),
        ).thenThrow(const BackendNetworkException('offline'));
        await provider.loadSessions();

        expect(provider.error, contains('offline'));
        expect(provider.sessions.map((s) => s.id), ['kept']);
        expect(provider.isLoading, isFalse);
      },
    );

    test('pending sessions are listed alongside saved ones', () async {
      store = InMemoryPendingWorkoutStore([
        _pendingInput('local', '2025-05-02T08:00:00.000Z'),
      ]);
      provider = WorkoutProvider(graphQLService: graphQL, pendingStore: store);
      when(
        () => graphQL.logWorkoutSession(any()),
      ).thenThrow(const BackendNetworkException('offline'));
      when(() => graphQL.getWorkoutSessions()).thenAnswer(
        (_) async => [
          TestData.workoutSession(id: 'a', startedAt: '2025-05-01T08:00Z'),
          TestData.workoutSession(id: 'b', startedAt: '2025-05-03T08:00Z'),
        ],
      );

      await provider.loadSessions();

      expect(provider.sessions.map((s) => s.id), ['b', 'local', 'a']);
      expect(provider.sessions.map((s) => s.isSynced), [true, false, true]);
    });
  });

  group('deleteSession', () {
    test('deletes a saved session on the backend', () async {
      when(
        () => graphQL.getWorkoutSessions(),
      ).thenAnswer((_) async => [TestData.workoutSession(id: 'gone')]);
      when(
        () => graphQL.deleteWorkoutSession('gone'),
      ).thenAnswer((_) async => true);
      await provider.loadSessions();

      expect(await provider.deleteSession('gone'), isTrue);
      expect(provider.sessions, isEmpty);
    });

    test('keeps the session when the backend delete fails', () async {
      when(
        () => graphQL.getWorkoutSessions(),
      ).thenAnswer((_) async => [TestData.workoutSession(id: 'kept')]);
      when(
        () => graphQL.deleteWorkoutSession('kept'),
      ).thenThrow(const BackendNetworkException('offline'));
      await provider.loadSessions();

      expect(await provider.deleteSession('kept'), isFalse);
      expect(provider.sessions.map((s) => s.id), ['kept']);
    });

    test(
      'drops a pending session locally without calling the backend',
      () async {
        store = InMemoryPendingWorkoutStore([
          _pendingInput('local', '2025-05-02T08:00:00.000Z'),
        ]);
        provider = WorkoutProvider(
          graphQLService: graphQL,
          pendingStore: store,
        );

        expect(await provider.deleteSession('local'), isTrue);

        expect(store.pending, isEmpty);
        expect(provider.sessions, isEmpty);
        verifyNever(() => graphQL.deleteWorkoutSession(any()));
      },
    );
  });
}

Map<String, dynamic> _pendingInput(String clientId, String startedAt) {
  return Input$LogWorkoutSessionInput(
    clientId: clientId,
    startedAt: startedAt,
    endedAt: startedAt,
    workoutType: 'Quick Log',
    exercises: [
      Input$LoggedExerciseInput(
        name: 'Squat',
        sets: [Input$LoggedSetInput(reps: 5, weightKg: 100)],
      ),
    ],
  ).toJson();
}
