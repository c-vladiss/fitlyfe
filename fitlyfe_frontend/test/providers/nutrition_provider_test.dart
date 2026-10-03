import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/graphql/operations/nutrition.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/food.graphql.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';

import '../mocks.dart';

void main() {
  late MockGraphQLService mockGraphQLService;
  late NutritionProvider provider;

  setUp(() {
    mockGraphQLService = MockGraphQLService();
    provider = NutritionProvider(graphQLService: mockGraphQLService);
  });

  group('NutritionProvider', () {
    group('initialization', () {
      test('starts with no logged food', () {
        expect(provider.todayFoods, isEmpty);
        expect(provider.todayCalories, 0);
      });

      test('starts with today as selected date', () {
        final now = DateTime.now();
        expect(provider.selectedDate.year, now.year);
        expect(provider.selectedDate.month, now.month);
        expect(provider.selectedDate.day, now.day);
      });

      test('starts with default meals', () {
        final meals = provider.getMealsForDate(DateTime.now());
        expect(meals.length, 4);
        expect(meals[0].name, 'Breakfast');
        expect(meals[1].name, 'Lunch');
        expect(meals[2].name, 'Dinner');
        expect(meals[3].name, 'Snacks');
      });

      test('is not loading initially', () {
        expect(provider.isLoading, false);
      });

      test('has no error initially', () {
        expect(provider.error, isNull);
      });
    });

    group('logged food', () {
      test('todayFoods lists the backend entries of the selected day', () async {
        when(() => mockGraphQLService.getDailyNutrition(any())).thenAnswer(
          (_) async => TestData.dailyNutrition(meals: [
            TestData.meal('Breakfast', [('e1', 'Oats', 80, 300), ('e2', 'Milk', 200, 120)]),
            TestData.meal('Dinner', [('e3', 'Salmon', 150, 310)]),
          ]),
        );

        await provider.loadDailyNutrition();

        final foods = provider.todayFoods;
        expect(foods.map((f) => f.id), ['e1', 'e2', 'e3']);
        expect(foods.map((f) => f.mealType), ['Breakfast', 'Breakfast', 'Dinner']);
        expect(foods.first.name, 'Oats');
        expect(foods.first.calories, 300);
        expect(foods.first.servingSizeG, 80);
      });

      test('totals come from the backend day', () async {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition(totalCalories: 1234, carbsG: 150, fatG: 42));

        await provider.loadDailyNutrition();

        expect(provider.todayCalories, 1234);
        expect(provider.todayCarbs, 150);
        expect(provider.todayFats, 42);
      });

      test('loading a date asks the backend for that date', () async {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());

        provider.setSelectedDate(DateTime(2026, 3, 5));
        await Future<void>.delayed(Duration.zero);

        verify(() => mockGraphQLService.getDailyNutrition('2026-03-05')).called(1);
      });
    });

    group('meal management', () {
      test('addMealGlobally adds meal to default list', () {
        final initialCount = provider.getMealsForDate(DateTime.now()).length;

        provider.addMealGlobally(MealInfo('Second Breakfast', '\uD83E\uDD50', 300));

        final meals = provider.getMealsForDate(DateTime.now());
        expect(meals.length, initialCount + 1);
        expect(meals.last.name, 'Second Breakfast');
      });

      test('deleteMealGlobally removes meal from all days', () {
        provider.deleteMealGlobally('Snacks');

        final meals = provider.getMealsForDate(DateTime.now());
        expect(meals.any((m) => m.name == 'Snacks'), false);
      });

      test('updateMealGlobally renames meal', () {
        final today = DateTime.now();

        provider.updateMealGlobally('Breakfast', MealInfo('Morning Meal', '\u2600', 500));

        final meals = provider.getMealsForDate(today);
        expect(meals.any((m) => m.name == 'Morning Meal'), true);
        expect(meals.any((m) => m.name == 'Breakfast'), false);
      });

      test('reorderMeals changes meal order', () {
        final today = DateTime.now();
        final before = provider.getMealsForDate(today);
        expect(before[0].name, 'Breakfast');
        expect(before[1].name, 'Lunch');

        // Move Lunch to first position
        provider.reorderMeals(today, 1, 0);

        final after = provider.getMealsForDate(today);
        expect(after[0].name, 'Lunch');
        expect(after[1].name, 'Breakfast');
      });
    });

    group('favorites and recent foods', () {
      final chicken = NutritionProvider.catalogFood(id: 'food-1', name: 'Chicken', caloriesPer100g: 165);
      final rice = NutritionProvider.catalogFood(id: 'food-2', name: 'Rice', caloriesPer100g: 130);

      void backendAddsEntries() {
        var n = 0;
        when(() => mockGraphQLService.addMealEntry(
              date: any(named: 'date'),
              mealType: any(named: 'mealType'),
              foodEntryId: any(named: 'foodEntryId'),
              quantityG: any(named: 'quantityG'),
            )).thenAnswer((_) async => _addMealEntryResult('entry-${++n}'));
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());
      }

      test('toggleFavorite adds and removes a food', () {
        expect(provider.isFavorite('food-1'), false);

        provider.toggleFavorite(chicken);
        expect(provider.isFavorite('food-1'), true);
        expect(provider.favoriteFoods.single.name, 'Chicken');

        provider.toggleFavorite(chicken);
        expect(provider.isFavorite('food-1'), false);
        expect(provider.favoriteFoods, isEmpty);
      });

      test('logged foods become recent, newest first and without duplicates', () async {
        backendAddsEntries();

        await provider.addFoodToMeal(foodEntryId: 'food-1', mealType: 'Lunch', quantityG: 100, food: chicken);
        await provider.addFoodToMeal(foodEntryId: 'food-2', mealType: 'Lunch', quantityG: 100, food: rice);
        await provider.addFoodToMeal(foodEntryId: 'food-1', mealType: 'Dinner', quantityG: 100, food: chicken);

        expect(provider.recentFoods.map((f) => f.name), ['Chicken', 'Rice']);
      });

      test('a food that failed to save is not added to recent', () async {
        when(() => mockGraphQLService.addMealEntry(
              date: any(named: 'date'),
              mealType: any(named: 'mealType'),
              foodEntryId: any(named: 'foodEntryId'),
              quantityG: any(named: 'quantityG'),
            )).thenThrow(const BackendNetworkException('offline'));

        final entryId = await provider.addFoodToMeal(
            foodEntryId: 'food-1', mealType: 'Lunch', quantityG: 100, food: chicken);

        expect(entryId, isNull);
        expect(provider.recentFoods, isEmpty);
        expect(provider.error, 'Failed to add food');
      });
    });

    group('catalog', () {
      test('foodFromSearchItem keeps per-100 g values and the serving size', () {
        final item = TestData.foodSearchResult().items.single;

        final food = NutritionProvider.foodFromSearchItem(item);

        expect(food.id, 'food-1');
        expect(food.name, 'Chicken Breast');
        expect(food.calories, 165);
        expect(food.kcalPer100g, 165);
        expect(food.protein, 31);
        expect(food.servingSizeG, 100);
      });

      test('searchFoods passes the entry types to the backend', () async {
        when(() => mockGraphQLService.searchFoodCatalog(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
              types: any(named: 'types'),
            )).thenAnswer((_) async => TestData.foodSearchResult());

        await provider.searchFoods('pasta', types: [Enum$FoodEntryType.RECIPE]);

        verify(() => mockGraphQLService.searchFoodCatalog(
              query: 'pasta',
              limit: 20,
              types: [Enum$FoodEntryType.RECIPE],
            )).called(1);
      });

      test('searchFoods returns null when the backend fails', () async {
        when(() => mockGraphQLService.searchFoodCatalog(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
              types: any(named: 'types'),
            )).thenThrow(const BackendNetworkException('offline'));

        expect(await provider.searchFoods('pasta'), isNull);
      });

      test('lookupBarcode maps the product to a food', () async {
        when(() => mockGraphQLService.getFoodByBarcode('5000112637922')).thenAnswer(
          (_) async => Query$FoodEntryByBarcode$foodEntryByBarcode(
            id: 'product-1',
            name: 'Cola',
            brand: 'Fizz Co',
            entryType: Enum$FoodEntryType.PRODUCT,
            barcode: '5000112637922',
            servingSizeG: 330,
            caloriesPer100g: 42,
            proteinPer100g: 0,
            carbsPer100g: 10.6,
            fatPer100g: 0,
          ),
        );

        final food = await provider.lookupBarcode('5000112637922');

        expect(food!.id, 'product-1');
        expect(food.brand, 'Fizz Co');
        expect(food.calories, 42);
        expect(food.servingSizeG, 330);
      });

      test('lookupBarcode returns null for unknown or failed lookups', () async {
        when(() => mockGraphQLService.getFoodByBarcode('unknown')).thenAnswer((_) async => null);
        when(() => mockGraphQLService.getFoodByBarcode('offline'))
            .thenThrow(const BackendNetworkException('offline'));

        expect(await provider.lookupBarcode('unknown'), isNull);
        expect(await provider.lookupBarcode('offline'), isNull);
      });
    });

    group('backend integration', () {
      test('loadDailyNutrition fetches data from backend', () async {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());

        await provider.loadDailyNutrition();

        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        expect(provider.dailyNutritionData, isNotNull);
        expect(provider.todayCalories, 1500);
        expect(provider.todayProtein, 100.0);
      });

      test('loadDailyNutrition handles network error', () async {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenThrow(const BackendNetworkException('Network error'));

        await provider.loadDailyNutrition();

        expect(provider.isLoading, false);
        expect(provider.error, 'Could not reach server');
      });

      test('loadDailyNutrition handles sync error', () async {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenThrow(const BackendSyncException('Sync error'));

        await provider.loadDailyNutrition();

        expect(provider.isLoading, false);
        expect(provider.error, 'Failed to load nutrition data');
      });

      test('searchFoods returns results from backend', () async {
        when(() => mockGraphQLService.searchFoodCatalog(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestData.foodSearchResult());

        final result = await provider.searchFoods('chicken');

        expect(result, isNotNull);
        expect(result!.items.length, 1);
        expect(result.items.first.name, 'Chicken Breast');
      });

      test('addFoodToMeal calls backend and refreshes data', () async {
        when(() => mockGraphQLService.addMealEntry(
              date: any(named: 'date'),
              mealType: any(named: 'mealType'),
              foodEntryId: any(named: 'foodEntryId'),
              quantityG: any(named: 'quantityG'),
            )).thenAnswer((_) async => Mutation$AddMealEntry$addMealEntry(
              entry: Mutation$AddMealEntry$addMealEntry$entry(
                id: 'entry-1',
                foodEntry: Mutation$AddMealEntry$addMealEntry$entry$foodEntry(
                  id: 'food-1',
                  name: 'Chicken',
                  brand: null,
                ),
                quantityG: 100.0,
                calories: 165,
                proteinG: 31.0,
                carbsG: 0.0,
                fatG: 3.6,
              ),
              mealSummary: Mutation$AddMealEntry$addMealEntry$mealSummary(
                mealId: 'meal-1',
                mealType: 'Lunch',
                totalCalories: 165,
                proteinG: 31.0,
                carbsG: 0.0,
                fatG: 3.6,
              ),
              dailySummary: Mutation$AddMealEntry$addMealEntry$dailySummary(
                totalCaloriesConsumed: 165,
                proteinGConsumed: 31.0,
                carbsGConsumed: 0.0,
                fatGConsumed: 3.6,
              ),
            ));

        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());

        final entryId = await provider.addFoodToMeal(
          foodEntryId: 'food-1',
          mealType: 'Lunch',
          quantityG: 100,
        );

        expect(entryId, 'entry-1');
        verify(() => mockGraphQLService.addMealEntry(
              date: any(named: 'date'),
              mealType: 'Lunch',
              foodEntryId: 'food-1',
              quantityG: 100,
            )).called(1);
        verify(() => mockGraphQLService.getDailyNutrition(any())).called(1);
      });

      test('deleteMealEntry calls backend and refreshes data', () async {
        when(() => mockGraphQLService.deleteMealEntry(any()))
            .thenAnswer((_) async => true);
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());

        final success = await provider.deleteMealEntry('entry-1');

        expect(success, true);
        verify(() => mockGraphQLService.deleteMealEntry('entry-1')).called(1);
      });
    });

    group('date selection', () {
      test('setSelectedDate updates selected date', () {
        when(() => mockGraphQLService.getDailyNutrition(any()))
            .thenAnswer((_) async => TestData.dailyNutrition());

        final newDate = DateTime(2026, 3, 15);
        provider.setSelectedDate(newDate);

        expect(provider.selectedDate.year, 2026);
        expect(provider.selectedDate.month, 3);
        expect(provider.selectedDate.day, 15);
      });
    });

    group('micronutrients', () {
      test('addVitamin increases micronutrient value', () {
        provider.addVitamin('vitamin_c', 50.0);
        expect(provider.dailyMicronutrients['vitamin_c'], 50.0);

        provider.addVitamin('vitamin_c', 25.0);
        expect(provider.dailyMicronutrients['vitamin_c'], 75.0);
      });

      test('resetDailyMicronutrients zeros all values', () {
        provider.addVitamin('vitamin_c', 50.0);
        provider.addVitamin('iron', 10.0);

        provider.resetDailyMicronutrients();

        expect(provider.dailyMicronutrients['vitamin_c'], 0.0);
        expect(provider.dailyMicronutrients['iron'], 0.0);
      });

      test('micronutrientPercentages calculates correctly', () {
        // vitamin_c RDI is 90mg
        provider.addVitamin('vitamin_c', 45.0); // 50%

        final percentages = provider.micronutrientPercentages;
        expect(percentages['vitamin_c'], 0.5);
      });
    });
  });
}

Mutation$AddMealEntry$addMealEntry _addMealEntryResult(String entryId) {
  return Mutation$AddMealEntry$addMealEntry(
    entry: Mutation$AddMealEntry$addMealEntry$entry(
      id: entryId,
      foodEntry: Mutation$AddMealEntry$addMealEntry$entry$foodEntry(id: 'food', name: 'Food'),
      quantityG: 100,
      calories: 100,
    ),
    mealSummary: Mutation$AddMealEntry$addMealEntry$mealSummary(
      mealId: 'meal',
      mealType: 'Lunch',
      totalCalories: 100,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
    ),
    dailySummary: Mutation$AddMealEntry$addMealEntry$dailySummary(
      totalCaloriesConsumed: 100,
      proteinGConsumed: 0,
      carbsGConsumed: 0,
      fatGConsumed: 0,
    ),
  );
}
