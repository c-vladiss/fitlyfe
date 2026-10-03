import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/screens/active_workout_page.dart';
import 'package:fitlyfe_frontend/services/pending_workout_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

final _routine = WorkoutRoutine(
  id: 'r1',
  name: 'Push Day',
  estimatedDuration: const Duration(minutes: 45),
  exercises: [Exercise(id: 'bench', name: 'Bench Press', sets: [])],
);

void main() {
  late MockGraphQLService graphQL;
  late WorkoutProvider workouts;
  late AppState appState;

  setUpAll(() {
    registerFallbackValue(
      Input$LogWorkoutSessionInput(startedAt: '', endedAt: '', exercises: []),
    );
  });

  setUp(() {
    graphQL = MockGraphQLService();
    workouts = WorkoutProvider(
      graphQLService: graphQL,
      pendingStore: InMemoryPendingWorkoutStore(),
    );
    appState = AppState(graphQLService: graphQL);
  });

  /// Opens the page on top of a placeholder home screen, like the app does.
  Future<void> openWorkout(WidgetTester tester) async {
    workouts.startSession(_routine);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider.value(value: workouts),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutPage(routine: _routine),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The elapsed-time clock ticks forever, so settle with bounded pumps.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> logSet(
    WidgetTester tester,
    String reps, [
    String weight = '',
  ]) async {
    await tester.tap(find.text('ADD SET'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('repsField')), reps);
    await tester.enterText(find.byKey(const Key('weightField')), weight);
    await tester.tap(find.text('LOG SET'));
    await settle(tester);
  }

  testWidgets('logs sets through the dialog', (tester) async {
    await openWorkout(tester);
    expect(find.text('No sets logged yet'), findsOneWidget);

    await logSet(tester, '10', '60');
    await logSet(tester, '8', '72,5');

    expect(find.text('1: 10 reps • 60kg'), findsOneWidget);
    expect(find.text('2: 8 reps • 72.5kg'), findsOneWidget);
    expect(
      workouts.activeSession!.exercises.single.sets.map(
        (s) => (s.reps, s.weight),
      ),
      [(10, 60.0), (8, 72.5)],
    );
  });

  testWidgets('the set dialog pre-fills the previous set', (tester) async {
    await openWorkout(tester);
    await logSet(tester, '10', '60');

    await tester.tap(find.text('ADD SET'));
    await settle(tester);

    expect(find.widgetWithText(TextField, '10'), findsOneWidget);
    expect(find.widgetWithText(TextField, '60'), findsOneWidget);
  });

  testWidgets('rejects a set without reps', (tester) async {
    await openWorkout(tester);

    await logSet(tester, '', '60');

    expect(find.text('Enter the number of reps'), findsOneWidget);
    expect(workouts.activeSession!.totalSets, 0);
  });

  testWidgets('a set can be removed', (tester) async {
    await openWorkout(tester);
    await logSet(tester, '10');

    await tester.tap(find.byTooltip('Remove set'));
    await settle(tester);

    expect(find.text('No sets logged yet'), findsOneWidget);
    expect(workouts.activeSession!.totalSets, 0);
  });

  testWidgets('adds an exercise that is not in the routine', (tester) async {
    await openWorkout(tester);

    await tester.tap(find.text('EXERCISE'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('exerciseNameField')),
      '  Cable Fly ',
    );
    await tester.tap(find.text('ADD'));
    await settle(tester);

    expect(find.text('Cable Fly'), findsOneWidget);
    expect(workouts.activeSession!.exercises.map((e) => e.name), [
      'Bench Press',
      'Cable Fly',
    ]);
  });

  testWidgets('finishing saves the workout and closes the page', (
    tester,
  ) async {
    when(
      () => graphQL.logWorkoutSession(any()),
    ).thenAnswer((_) async => TestData.workoutSession());
    await openWorkout(tester);
    await logSet(tester, '10', '60');

    await tester.tap(find.text('FINISH'));
    await settle(tester);

    verify(() => graphQL.logWorkoutSession(any())).called(1);
    expect(find.byType(ActiveWorkoutPage), findsNothing);
    expect(find.text('Workout completed! High five! ✋'), findsOneWidget);
    expect(appState.selectedPageIndex, 2);
  });

  testWidgets('finishing while offline keeps the workout on the device', (
    tester,
  ) async {
    when(
      () => graphQL.logWorkoutSession(any()),
    ).thenThrow(const BackendNetworkException('offline'));
    await openWorkout(tester);
    await logSet(tester, '10', '60');

    await tester.tap(find.text('FINISH'));
    await settle(tester);

    expect(find.byType(ActiveWorkoutPage), findsNothing);
    expect(find.textContaining('saved on this device'), findsOneWidget);
    expect(workouts.pendingCount, 1);
  });

  testWidgets('finishing without sets does not call the backend', (
    tester,
  ) async {
    await openWorkout(tester);

    await tester.tap(find.text('FINISH'));
    await settle(tester);

    verifyNever(() => graphQL.logWorkoutSession(any()));
    expect(find.textContaining('nothing was saved'), findsOneWidget);
  });

  testWidgets('leaving asks for confirmation and discards the workout', (
    tester,
  ) async {
    await openWorkout(tester);
    await logSet(tester, '10', '60');

    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
    expect(find.text('Leave workout?'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await settle(tester);
    expect(find.byType(ActiveWorkoutPage), findsOneWidget);
    expect(workouts.activeSession, isNotNull);

    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
    await tester.tap(find.text('LEAVE'));
    await settle(tester);

    expect(find.byType(ActiveWorkoutPage), findsNothing);
    expect(workouts.activeSession, isNull);
    verifyNever(() => graphQL.logWorkoutSession(any()));
  });

  testWidgets('the system back gesture also asks for confirmation', (
    tester,
  ) async {
    await openWorkout(tester);

    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(find.text('Leave workout?'), findsOneWidget);
    expect(find.byType(ActiveWorkoutPage), findsOneWidget);
  });
}
