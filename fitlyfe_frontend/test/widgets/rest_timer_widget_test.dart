import 'package:fitlyfe_frontend/widgets/rest_timer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late TestApp app;

  setUp(() => app = TestApp());

  Future<void> pumpTimer(WidgetTester tester) => app.pump(
    tester,
    const Scaffold(body: SingleChildScrollView(child: RestTimerWidget())),
  );

  Future<void> advance(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('starts at one minute', (tester) async {
    await pumpTimer(tester);
    expect(find.text('1:00'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('counts down while running and pauses', (tester) async {
    await pumpTimer(tester);

    await tester.tap(find.text('START'));
    await advance(tester, 5);
    expect(find.text('0:55'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);

    await tester.tap(find.text('PAUSE'));
    await advance(tester, 5);
    expect(
      find.text('0:55'),
      findsOneWidget,
      reason: 'paused timers must not move',
    );

    await tester.tap(find.text('START'));
    await advance(tester, 2);
    expect(find.text('0:53'), findsOneWidget);
  });

  testWidgets('reset goes back to the selected duration', (tester) async {
    await pumpTimer(tester);
    await tester.tap(find.text('START'));
    await advance(tester, 10);

    await tester.tap(find.text('RESET'));
    await tester.pump();

    expect(find.text('1:00'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('quick select changes the duration, but not while running', (
    tester,
  ) async {
    await pumpTimer(tester);

    await tester.tap(find.text('90s'));
    await tester.pump();
    expect(find.text('1:30'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.tap(find.text('30s'));
    await tester.pump();
    expect(find.text('1:30'), findsOneWidget);

    await tester.tap(find.text('PAUSE'));
  });

  testWidgets('finishes exactly when the time is up', (tester) async {
    await pumpTimer(tester);
    await tester.tap(find.text('30s'));
    await tester.pump();
    await tester.tap(find.text('START'));

    await advance(tester, 29);
    expect(find.text('0:01'), findsOneWidget);
    expect(find.text('Rest period completed!'), findsNothing);

    await advance(tester, 1);
    await tester.pump(const Duration(milliseconds: 500)); // snackbar animation

    expect(find.text('Rest period completed!'), findsOneWidget);
    // Ready for the next set
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}
