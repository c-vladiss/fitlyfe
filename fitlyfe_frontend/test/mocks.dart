import 'package:mocktail/mocktail.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/auth.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/user.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/nutrition.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/food.graphql.dart';

/// Mock GraphQLService for testing providers.
class MockGraphQLService extends Mock implements GraphQLService {}

/// Factory for creating test data.
class TestData {
  static Mutation$SyncUser$syncUser syncUserResult({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? firstName = 'Test',
    String? lastName = 'User',
    bool requiresOnboarding = false,
    Mutation$SyncUser$syncUser$profile? profile,
  }) {
    return Mutation$SyncUser$syncUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      requiresOnboarding: requiresOnboarding,
      profile: profile,
    );
  }

  static Mutation$SyncUser$syncUser$profile userProfile({
    double? heightCm = 180.0,
    double? weightKg = 75.0,
    String? dateOfBirth = '1990-01-15',
    String? goal = 'lose_weight',
    String? displayName = 'Test User',
  }) {
    return Mutation$SyncUser$syncUser$profile(
      heightCm: heightCm,
      weightKg: weightKg,
      dateOfBirth: dateOfBirth,
      goal: goal,
      displayName: displayName,
    );
  }

  static Query$UserGoals$userGoals userGoals({
    int dailyCalories = 2000,
    double dailyProteinG = 150.0,
    double dailyCarbsG = 250.0,
    double dailyFatG = 65.0,
    double? goalWeightKg = 70.0,
  }) {
    return Query$UserGoals$userGoals(
      dailyCalories: dailyCalories,
      dailyProteinG: dailyProteinG,
      dailyCarbsG: dailyCarbsG,
      dailyFatG: dailyFatG,
      goalWeightKg: goalWeightKg,
    );
  }

  static Query$DailyNutrition$dailyNutrition dailyNutrition({
    String id = 'daily-1',
    String date = '2026-03-09',
    int? totalCalories = 1500,
    double? proteinG = 100.0,
    double? carbsG = 150.0,
    double? fatG = 50.0,
    int? waterMl = 2000,
  }) {
    return Query$DailyNutrition$dailyNutrition(
      id: id,
      date: date,
      totalCalories: totalCalories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      waterMl: waterMl,
      goals: Query$DailyNutrition$dailyNutrition$goals(
        totalCalories: 2000,
        totalProteinG: 150.0,
        totalCarbsG: 250.0,
        totalFatG: 65.0,
      ),
      mealTemplate: [],
      meals: [],
    );
  }

  static Query$SearchFoodCatalog$searchFoodCatalog foodSearchResult({
    List<Query$SearchFoodCatalog$searchFoodCatalog$items>? items,
    int total = 1,
    bool hasMore = false,
  }) {
    return Query$SearchFoodCatalog$searchFoodCatalog(
      items: items ?? [
        Query$SearchFoodCatalog$searchFoodCatalog$items(
          id: 'food-1',
          name: 'Chicken Breast',
          brand: null,
          entryType: Enum$FoodEntryType.FOOD,
          barcode: null,
          servingSizeG: 100.0,
          caloriesPer100g: 165.0,
          proteinPer100g: 31.0,
          carbsPer100g: 0.0,
          fatPer100g: 3.6,
        ),
      ],
      total: total,
      hasMore: hasMore,
    );
  }
}
