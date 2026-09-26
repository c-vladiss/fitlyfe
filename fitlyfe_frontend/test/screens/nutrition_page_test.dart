import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/screens/nutrition_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

void main() {
  late MockGraphQLService graphQL;
  late NutritionProvider nutrition;

  setUp(() {
    graphQL = MockGraphQLService();
    nutrition = NutritionProvider(graphQLService: graphQL);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(graphQLService: graphQL),
          ),
          ChangeNotifierProvider.value(value: nutrition),
          ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ],
        child: const MaterialApp(home: NutritionPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'loads the selected day from the backend and lists logged food per meal',
    (tester) async {
      when(() => graphQL.getDailyNutrition(any())).thenAnswer(
        (_) async => TestData.dailyNutrition(
          meals: [
            TestData.meal('Breakfast', [('e1', 'Oats', 80, 300)]),
            TestData.meal('Dinner', [('e2', 'Salmon', 150, 310)]),
          ],
        ),
      );

      await pumpPage(tester);

      verify(() => graphQL.getDailyNutrition(any())).called(1);
      expect(find.text('- Oats'), findsOneWidget);
      expect(find.text('- Salmon'), findsOneWidget);
      expect(find.text('300 kcal'), findsOneWidget);
      // Meal totals come from its entries
      expect(find.textContaining('300 /'), findsOneWidget);
    },
  );

  testWidgets('deleting a food removes the entry on the backend', (
    tester,
  ) async {
    var day = TestData.dailyNutrition(
      meals: [
        TestData.meal('Lunch', [('e1', 'Pasta', 200, 400)]),
      ],
    );
    when(() => graphQL.getDailyNutrition(any())).thenAnswer((_) async => day);
    when(() => graphQL.deleteMealEntry('e1')).thenAnswer((_) async {
      day = TestData.dailyNutrition(meals: [TestData.meal('Lunch', [])]);
      return true;
    });
    await pumpPage(tester);
    expect(find.text('- Pasta'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Pasta'));
    await tester.pumpAndSettle();

    verify(() => graphQL.deleteMealEntry('e1')).called(1);
    expect(find.text('- Pasta'), findsNothing);
  });

  testWidgets('a failed delete keeps the food and tells the user', (
    tester,
  ) async {
    when(() => graphQL.getDailyNutrition(any())).thenAnswer(
      (_) async => TestData.dailyNutrition(
        meals: [
          TestData.meal('Lunch', [('e1', 'Pasta', 200, 400)]),
        ],
      ),
    );
    when(() => graphQL.deleteMealEntry('e1')).thenAnswer((_) async => false);
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Remove Pasta'));
    await tester.pumpAndSettle();

    expect(find.text('- Pasta'), findsOneWidget);
    expect(
      find.text('Could not remove the food. Please try again.'),
      findsOneWidget,
    );
  });
}
