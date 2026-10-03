import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/health_provider.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

/// HealthProvider without the health plugin: tests set the values directly.
class FakeHealthProvider extends HealthProvider {
  bool authorized;
  int fakeSteps;
  int fakeActiveMinutes;
  int authorizationRequests = 0;

  FakeHealthProvider({
    this.authorized = false,
    this.fakeSteps = 0,
    this.fakeActiveMinutes = 0,
  });

  @override
  bool get isAuthorized => authorized;

  @override
  int get steps => fakeSteps;

  @override
  int get activeMinutes => fakeActiveMinutes;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> fetchData() async {}

  @override
  Future<bool> requestAuthorization() async {
    authorizationRequests++;
    authorized = true;
    notifyListeners();
    return true;
  }
}

/// The app's providers with a mocked backend, so screens can be pumped alone.
class TestApp {
  final MockGraphQLService graphQL = MockGraphQLService();
  late final AppState appState = AppState(graphQLService: graphQL);
  late final NutritionProvider nutrition = NutritionProvider(
    graphQLService: graphQL,
  );
  final WorkoutProvider workouts = WorkoutProvider();
  final ProgressProvider progress = ProgressProvider();
  final TranslationProvider translations = TranslationProvider();
  final FakeHealthProvider health;

  TestApp({FakeHealthProvider? health})
    : health = health ?? FakeHealthProvider();

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ChangeNotifierProvider<WorkoutProvider>.value(value: workouts),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
        ChangeNotifierProvider<TranslationProvider>.value(value: translations),
        ChangeNotifierProvider<HealthProvider>.value(value: health),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    );
  }

  /// Pumps [home] on a large screen. The test font draws every glyph as a
  /// full square, so text is much wider than on a device; the extra width
  /// keeps font-only overflows out of the results.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(700, 1600),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(home));
  }
}
