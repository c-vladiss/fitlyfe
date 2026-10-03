import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/graphql/operations/food.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/nutrition.graphql.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/screens/food_details_page.dart';
import 'package:fitlyfe_frontend/screens/nutrition_page.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

Query$SearchFoodCatalog$searchFoodCatalog$items _item(
  String id,
  String name, {
  double? servingSizeG,
  double kcal = 100,
  String? brand,
  Enum$FoodEntryType type = Enum$FoodEntryType.FOOD,
}) {
  return Query$SearchFoodCatalog$searchFoodCatalog$items(
    id: id,
    name: name,
    brand: brand,
    entryType: type,
    servingSizeG: servingSizeG,
    caloriesPer100g: kcal,
    proteinPer100g: 10,
    carbsPer100g: 20,
    fatPer100g: 5,
  );
}

Mutation$AddMealEntry$addMealEntry _added(String entryId) {
  return Mutation$AddMealEntry$addMealEntry(
    entry: Mutation$AddMealEntry$addMealEntry$entry(
      id: entryId,
      foodEntry: Mutation$AddMealEntry$addMealEntry$entry$foodEntry(
        id: 'f',
        name: 'f',
      ),
    ),
    mealSummary: Mutation$AddMealEntry$addMealEntry$mealSummary(
      mealId: 'm',
      mealType: 'Lunch',
      totalCalories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
    ),
    dailySummary: Mutation$AddMealEntry$addMealEntry$dailySummary(
      totalCaloriesConsumed: 0,
      proteinGConsumed: 0,
      carbsGConsumed: 0,
      fatGConsumed: 0,
    ),
  );
}

void main() {
  late MockGraphQLService graphQL;
  late NutritionProvider nutrition;

  setUp(() {
    graphQL = MockGraphQLService();
    nutrition = NutritionProvider(graphQLService: graphQL);
    when(
      () => graphQL.getDailyNutrition(any()),
    ).thenAnswer((_) async => TestData.dailyNutrition());
  });

  void catalogReturns(
    List<Query$SearchFoodCatalog$searchFoodCatalog$items> items,
  ) {
    when(
      () => graphQL.searchFoodCatalog(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        types: any(named: 'types'),
      ),
    ).thenAnswer(
      (_) async => TestData.foodSearchResult(items: items, total: items.length),
    );
  }

  void backendAddsEntries() {
    when(
      () => graphQL.addMealEntry(
        date: any(named: 'date'),
        mealType: any(named: 'mealType'),
        foodEntryId: any(named: 'foodEntryId'),
        quantityG: any(named: 'quantityG'),
      ),
    ).thenAnswer((_) async => _added('entry-1'));
  }

  Widget app(Widget home) => MultiProvider(
    providers: [ChangeNotifierProvider.value(value: nutrition)],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );

  /// Lets the one-second "added" check-mark animation run out.
  Future<void> finishAnimations(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('foodSearchField')), text);
    // Past the debounce
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  group('AddFoodSearchSheet', () {
    testWidgets('shows no hardcoded foods before searching', (tester) async {
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));

      expect(
        find.text('Search thousands of foods, or scan a barcode.'),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNothing);
      // The mock "Meals" category is gone
      expect(find.text('Meals'), findsNothing);
      verifyNever(
        () => graphQL.searchFoodCatalog(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          types: any(named: 'types'),
        ),
      );
    });

    testWidgets('searches the catalog once typing pauses', (tester) async {
      catalogReturns([
        _item(
          'f1',
          'Chicken Breast',
          servingSizeG: 150,
          kcal: 165,
          brand: 'Farm',
        ),
        _item('f2', 'Chicken Thigh', kcal: 209),
      ]);
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));

      await tester.enterText(find.byKey(const Key('foodSearchField')), 'chi');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        find.byKey(const Key('foodSearchField')),
        'chicken',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Only the final text is searched, for foods and branded products
      verify(
        () => graphQL.searchFoodCatalog(
          query: 'chicken',
          limit: 25,
          types: [Enum$FoodEntryType.FOOD, Enum$FoodEntryType.PRODUCT],
        ),
      ).called(1);
      verifyNever(
        () => graphQL.searchFoodCatalog(
          query: 'chi',
          limit: any(named: 'limit'),
          types: any(named: 'types'),
        ),
      );
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Farm • 1 serving (150 g)'), findsOneWidget);
      // kcal shown for one serving: 165 kcal/100 g * 1.5
      expect(find.text('248 kcal'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('209 kcal'), findsOneWidget);
    });

    testWidgets('the Recipes category searches recipes', (tester) async {
      catalogReturns([
        _item('r1', 'Pasta Bake', type: Enum$FoodEntryType.RECIPE),
      ]);
      await tester.pumpWidget(
        app(const AddFoodSearchSheet(mealType: 'Dinner')),
      );

      await tester.tap(find.text('Recipes'));
      await search(tester, 'pasta');

      verify(
        () => graphQL.searchFoodCatalog(
          query: 'pasta',
          limit: 25,
          types: [Enum$FoodEntryType.RECIPE],
        ),
      ).called(1);
      expect(find.text('Pasta Bake'), findsOneWidget);
    });

    testWidgets('explains when nothing matches or the backend is unreachable', (
      tester,
    ) async {
      catalogReturns([]);
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));

      await search(tester, 'zzzz');
      expect(find.textContaining('No foods found for "zzzz"'), findsOneWidget);

      when(
        () => graphQL.searchFoodCatalog(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          types: any(named: 'types'),
        ),
      ).thenThrow(const BackendNetworkException('offline'));
      await search(tester, 'apple');
      expect(
        find.textContaining('Could not reach the food database'),
        findsOneWidget,
      );
    });

    testWidgets('quick add logs one serving in the meal on the backend', (
      tester,
    ) async {
      catalogReturns([_item('f1', 'Chicken Breast', servingSizeG: 150)]);
      backendAddsEntries();
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));
      await search(tester, 'chicken');

      await tester.tap(find.bySemanticsLabel('Add Chicken Breast'));
      await tester.pumpAndSettle();

      verify(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: 'Lunch',
          foodEntryId: 'f1',
          quantityG: 150,
        ),
      ).called(1);
      expect(find.text('Just Added (1)'), findsOneWidget);
      expect(nutrition.recentFoods.single.name, 'Chicken Breast');
      await finishAnimations(tester);
    });

    testWidgets('quick add uses 100 g when the serving size is unknown', (
      tester,
    ) async {
      catalogReturns([_item('f2', 'Rice')]);
      backendAddsEntries();
      await tester.pumpWidget(
        app(const AddFoodSearchSheet(mealType: 'Dinner')),
      );
      await search(tester, 'rice');

      await tester.tap(find.bySemanticsLabel('Add Rice'));
      await finishAnimations(tester);

      verify(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: 'Dinner',
          foodEntryId: 'f2',
          quantityG: 100,
        ),
      ).called(1);
    });

    testWidgets('a failed quick add tells the user', (tester) async {
      catalogReturns([_item('f1', 'Chicken Breast')]);
      when(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: any(named: 'mealType'),
          foodEntryId: any(named: 'foodEntryId'),
          quantityG: any(named: 'quantityG'),
        ),
      ).thenThrow(const BackendNetworkException('offline'));
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));
      await search(tester, 'chicken');

      await tester.tap(find.bySemanticsLabel('Add Chicken Breast'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not add the food. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Just Added'), findsOneWidget);
    });

    testWidgets('favorites and recent tabs list real catalog foods', (
      tester,
    ) async {
      catalogReturns([_item('f1', 'Chicken Breast'), _item('f2', 'Rice')]);
      backendAddsEntries();
      await tester.pumpWidget(app(const AddFoodSearchSheet(mealType: 'Lunch')));
      await search(tester, 'food');

      await tester.tap(find.bySemanticsLabel('Add to favorites').first);
      await tester.tap(find.bySemanticsLabel('Add Rice'));
      await finishAnimations(tester);

      await tester.enterText(find.byKey(const Key('foodSearchField')), '');
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Rice'), findsNothing);

      // The search text filters these tabs locally
      await tester.enterText(find.byKey(const Key('foodSearchField')), 'rice');
      await tester.pumpAndSettle();
      expect(find.text('Chicken Breast'), findsNothing);
      await tester.enterText(find.byKey(const Key('foodSearchField')), '');

      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Chicken Breast'), findsNothing);
    });
  });

  group('FoodDetailsPage', () {
    final chicken = NutritionProvider.catalogFood(
      id: 'f1',
      name: 'Chicken Breast',
      brand: 'Farm',
      servingSizeG: 150,
      caloriesPer100g: 200,
      proteinPer100g: 30,
      carbsPer100g: 0,
      fatPer100g: 8,
    );

    Future<Object?> openDetails(WidgetTester tester, Food food) async {
      Object? popped;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FoodDetailsPage(food: food, mealType: 'Lunch'),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return popped;
    }

    testWidgets('defaults to one serving and shows its nutrition', (
      tester,
    ) async {
      await openDetails(tester, chicken);

      expect(find.text('Farm'), findsOneWidget);
      expect(find.text('Serving (150 g)'), findsOneWidget);
      // 200 kcal/100 g * 1.5
      expect(find.text('300 kcal'), findsWidgets);
      expect(find.text('45.0 g'), findsWidgets); // protein
      // The fake badges and paywall are gone
      expect(find.text('Verified nutrition facts'), findsNothing);
      expect(find.text('Unlock All'), findsNothing);
      expect(find.text('Pro'), findsNothing);
    });

    testWidgets('logs the chosen amount in grams', (tester) async {
      backendAddsEntries();
      await openDetails(tester, chicken);

      await tester.enterText(find.byKey(const Key('quantityField')), '2');
      await tester.pump();
      expect(find.text('600 kcal'), findsWidgets);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      verify(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: 'Lunch',
          foodEntryId: 'f1',
          quantityG: 300,
        ),
      ).called(1);
      expect(find.byType(FoodDetailsPage), findsNothing);
      expect(find.text('Food added successfully'), findsOneWidget);
    });

    testWidgets('rejects an invalid amount', (tester) async {
      await openDetails(tester, chicken);

      await tester.enterText(find.byKey(const Key('quantityField')), '0');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid amount'), findsOneWidget);
      expect(find.byType(FoodDetailsPage), findsOneWidget);
      verifyNever(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: any(named: 'mealType'),
          foodEntryId: any(named: 'foodEntryId'),
          quantityG: any(named: 'quantityG'),
        ),
      );
    });

    testWidgets('stays open when saving fails', (tester) async {
      when(
        () => graphQL.addMealEntry(
          date: any(named: 'date'),
          mealType: any(named: 'mealType'),
          foodEntryId: any(named: 'foodEntryId'),
          quantityG: any(named: 'quantityG'),
        ),
      ).thenThrow(const BackendNetworkException('offline'));
      await openDetails(tester, chicken);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodDetailsPage), findsOneWidget);
      expect(
        find.text('Could not add the food. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
