import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/graphql/operations/nutrition.graphql.dart';

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
      test('starts with empty foods list', () {
        expect(provider.foods, isEmpty);
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

    group('local food management', () {
      test('addFood adds food to list', () {
        final food = Food(
          id: 'test-1',
          name: 'Test Food',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: DateTime.now(),
        );

        provider.addFood(food);

        expect(provider.foods.length, 1);
        expect(provider.foods.first.name, 'Test Food');
      });

      test('removeFood removes food from list', () {
        final food = Food(
          id: 'test-1',
          name: 'Test Food',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: DateTime.now(),
        );

        provider.addFood(food);
        expect(provider.foods.length, 1);

        provider.removeFood('test-1');
        expect(provider.foods, isEmpty);
      });

      test('todayFoods filters by selected date', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        provider.addFood(Food(
          id: 'today-1',
          name: 'Today Food',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: today,
        ));

        provider.addFood(Food(
          id: 'yesterday-1',
          name: 'Yesterday Food',
          calories: 200,
          protein: 20,
          carbs: 40,
          fats: 10,
          dateAdded: yesterday,
        ));

        expect(provider.todayFoods.length, 1);
        expect(provider.todayFoods.first.name, 'Today Food');
      });

      test('todayCalories sums calories from today foods', () {
        final today = DateTime.now();

        provider.addFood(Food(
          id: 'food-1',
          name: 'Food 1',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: today,
        ));

        provider.addFood(Food(
          id: 'food-2',
          name: 'Food 2',
          calories: 200,
          protein: 20,
          carbs: 40,
          fats: 10,
          dateAdded: today,
        ));

        expect(provider.todayCalories, 300);
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

      test('updateMealGlobally renames meal and cascades to foods', () {
        final today = DateTime.now();
        provider.addFood(Food(
          id: 'food-1',
          name: 'Eggs',
          calories: 150,
          protein: 12,
          carbs: 1,
          fats: 10,
          dateAdded: today,
          mealType: 'Breakfast',
        ));

        provider.updateMealGlobally('Breakfast', MealInfo('Morning Meal', '\u2600', 500));

        // Check meal was renamed
        final meals = provider.getMealsForDate(today);
        expect(meals.any((m) => m.name == 'Morning Meal'), true);
        expect(meals.any((m) => m.name == 'Breakfast'), false);

        // Check food mealType was cascaded
        expect(provider.foods.first.mealType, 'Morning Meal');
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

    group('favorites', () {
      test('toggleFavoritePreset adds and removes from favorites', () {
        expect(provider.favoritePresetIds.contains('p1'), false);

        provider.toggleFavoritePreset('p1');
        expect(provider.favoritePresetIds.contains('p1'), true);

        provider.toggleFavoritePreset('p1');
        expect(provider.favoritePresetIds.contains('p1'), false);
      });

      test('toggleFavoriteRecipe adds and removes from favorites', () {
        expect(provider.favoriteRecipeIds.contains('r1'), false);

        provider.toggleFavoriteRecipe('r1');
        expect(provider.favoriteRecipeIds.contains('r1'), true);

        provider.toggleFavoriteRecipe('r1');
        expect(provider.favoriteRecipeIds.contains('r1'), false);
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

        final success = await provider.addFoodToMeal(
          foodEntryId: 'food-1',
          mealType: 'Lunch',
          quantityG: 100,
        );

        expect(success, true);
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

    group('presets', () {
      test('presets list is not empty', () {
        expect(NutritionProvider.presets.isNotEmpty, true);
      });

      test('presets have valid data', () {
        for (final preset in NutritionProvider.presets) {
          expect(preset.id.isNotEmpty, true);
          expect(preset.name.isNotEmpty, true);
          expect(preset.calories >= 0, true);
          expect(preset.protein >= 0, true);
          expect(preset.carbs >= 0, true);
          expect(preset.fats >= 0, true);
        }
      });
    });
  });
}
