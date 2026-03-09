import 'package:fitlyfe_frontend/config/app_config.dart';
import 'package:fitlyfe_frontend/graphql/operations/auth.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/food.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/nutrition.graphql.dart';
import 'package:fitlyfe_frontend/graphql/operations/user.graphql.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the backend server cannot be reached (network/connection error).
class BackendNetworkException implements Exception {
  final String message;
  const BackendNetworkException(this.message);
  @override
  String toString() => 'BackendNetworkException: $message';
}

/// Thrown when the backend rejects the request (auth failure, bad response, etc.).
class BackendSyncException implements Exception {
  final String message;
  const BackendSyncException(this.message);
  @override
  String toString() => 'BackendSyncException: $message';
}

/// Type alias for the syncUser mutation result.
typedef SyncUserResult = Mutation$SyncUser$syncUser;

/// Type alias for the user profile from syncUser.
typedef SyncUserProfile = Mutation$SyncUser$syncUser$profile;

/// Type alias for daily nutrition query result.
typedef DailyNutritionResult = Query$DailyNutrition$dailyNutrition;

/// Type alias for food search result.
typedef FoodSearchResult = Query$SearchFoodCatalog$searchFoodCatalog;

/// Type alias for food entry.
typedef FoodEntry = Query$SearchFoodCatalog$searchFoodCatalog$items;

/// Type alias for user goals query result.
typedef UserGoalsResult = Query$UserGoals$userGoals;

class GraphQLService {
  late GraphQLClient _client;

  GraphQLService() {
    final HttpLink httpLink = HttpLink(AppConfig.apiUrl);

    final AuthLink authLink = AuthLink(
      getToken: () {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        return token != null ? 'Bearer $token' : null;
      },
    );

    _client = GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  /// Handles GraphQL exceptions, converting them to appropriate exception types.
  Never _handleException(OperationException ex, String operation) {
    debugPrint('GraphQL $operation error: $ex');
    if (ex.linkException is NetworkException) {
      throw BackendNetworkException(ex.toString());
    }
    throw BackendSyncException(ex.toString());
  }

  // ── Auth Operations ─────────────────────────────────────────────────────

  /// Called immediately after Supabase sign-in.
  /// Upserts the user on the backend and returns whether onboarding is needed.
  Future<SyncUserResult> syncUser() async {
    if (kDebugMode) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      debugPrint(
        'syncUser: Supabase token is ${token == null ? "NULL" : "present (${token.substring(0, 20)}...)"}',
      );
    }

    final result = await _client.mutate(
      MutationOptions(document: documentNodeMutationSyncUser),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'syncUser');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('syncUser mutation returned null data');
    }

    return Mutation$SyncUser.fromJson(data).syncUser;
  }

  /// Called at the end of the onboarding flow to mark it complete on the backend.
  Future<bool> completeOnboarding() async {
    final result = await _client.mutate(
      MutationOptions(document: documentNodeMutationCompleteOnboarding),
    );

    if (result.hasException) {
      debugPrint('GraphQL completeOnboarding error: ${result.exception}');
      return false;
    }

    final data = result.data;
    if (data == null) return false;

    return Mutation$CompleteOnboarding.fromJson(data).completeOnboarding;
  }

  // ── User Operations ─────────────────────────────────────────────────────

  /// Fetches the current user's nutrition goals.
  Future<UserGoalsResult> getUserGoals() async {
    final result = await _client.query(
      QueryOptions(document: documentNodeQueryUserGoals),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'userGoals');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('userGoals query returned null data');
    }

    return Query$UserGoals.fromJson(data).userGoals;
  }

  /// Saves or updates the user's fitness profile on the backend.
  Future<Mutation$UpdateUserProfile$updateUserProfile> updateUserProfile({
    String? displayName,
    double? heightCm,
    double? weightKg,
    String? dateOfBirth,
    String? goal,
  }) async {
    final input = Input$UpdateUserProfileInput(
      displayName: displayName,
      heightCm: heightCm,
      weightKg: weightKg,
      dateOfBirth: dateOfBirth,
      goal: goal,
    );

    final result = await _client.mutate(
      MutationOptions(
        document: documentNodeMutationUpdateUserProfile,
        variables: Variables$Mutation$UpdateUserProfile(input: input).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'updateUserProfile');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('updateUserProfile returned null data');
    }

    return Mutation$UpdateUserProfile.fromJson(data).updateUserProfile;
  }

  /// Updates the user's nutrition goals.
  Future<Mutation$UpdateUserGoals$updateUserGoals> updateUserGoals({
    int? dailyCalories,
    double? dailyProteinG,
    double? dailyCarbsG,
    double? dailyFatG,
    double? goalWeightKg,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: documentNodeMutationUpdateUserGoals,
        variables: Variables$Mutation$UpdateUserGoals(
          dailyCalories: dailyCalories,
          dailyProteinG: dailyProteinG,
          dailyCarbsG: dailyCarbsG,
          dailyFatG: dailyFatG,
          goalWeightKg: goalWeightKg,
        ).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'updateUserGoals');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('updateUserGoals returned null data');
    }

    return Mutation$UpdateUserGoals.fromJson(data).updateUserGoals;
  }

  // ── Nutrition Operations ────────────────────────────────────────────────

  /// Fetches daily nutrition data for a specific date.
  Future<DailyNutritionResult> getDailyNutrition(String date) async {
    final result = await _client.query(
      QueryOptions(
        document: documentNodeQueryDailyNutrition,
        variables: Variables$Query$DailyNutrition(date: date).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'dailyNutrition');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('dailyNutrition query returned null data');
    }

    return Query$DailyNutrition.fromJson(data).dailyNutrition;
  }

  /// Adds a food entry to a meal.
  Future<Mutation$AddMealEntry$addMealEntry> addMealEntry({
    required String date,
    required String mealType,
    required String foodEntryId,
    required double quantityG,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: documentNodeMutationAddMealEntry,
        variables: Variables$Mutation$AddMealEntry(
          date: date,
          mealType: mealType,
          foodEntryId: foodEntryId,
          quantityG: quantityG,
        ).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'addMealEntry');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('addMealEntry returned null data');
    }

    return Mutation$AddMealEntry.fromJson(data).addMealEntry;
  }

  /// Updates a meal entry's quantity or food.
  Future<Mutation$UpdateMealEntry$updateMealEntry> updateMealEntry({
    required String entryId,
    double? quantityG,
    String? foodEntryId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: documentNodeMutationUpdateMealEntry,
        variables: Variables$Mutation$UpdateMealEntry(
          entryId: entryId,
          quantityG: quantityG,
          foodEntryId: foodEntryId,
        ).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'updateMealEntry');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('updateMealEntry returned null data');
    }

    return Mutation$UpdateMealEntry.fromJson(data).updateMealEntry;
  }

  /// Deletes a meal entry.
  Future<bool> deleteMealEntry(String entryId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: documentNodeMutationDeleteMealEntry,
        variables: Variables$Mutation$DeleteMealEntry(entryId: entryId).toJson(),
      ),
    );

    if (result.hasException) {
      debugPrint('GraphQL deleteMealEntry error: ${result.exception}');
      return false;
    }

    final data = result.data;
    if (data == null) return false;

    return Mutation$DeleteMealEntry.fromJson(data).deleteMealEntry;
  }

  // ── Food Catalog Operations ─────────────────────────────────────────────

  /// Searches the food catalog.
  Future<FoodSearchResult> searchFoodCatalog({
    required String query,
    List<Enum$FoodEntryType>? types,
    int? limit,
    int? offset,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: documentNodeQuerySearchFoodCatalog,
        variables: Variables$Query$SearchFoodCatalog(
          query: query,
          types: types,
          limit: limit,
          offset: offset,
        ).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'searchFoodCatalog');
    }

    final data = result.data;
    if (data == null) {
      throw BackendSyncException('searchFoodCatalog query returned null data');
    }

    return Query$SearchFoodCatalog.fromJson(data).searchFoodCatalog;
  }

  /// Looks up a food entry by barcode.
  Future<Query$FoodEntryByBarcode$foodEntryByBarcode?> getFoodByBarcode(
    String barcode,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: documentNodeQueryFoodEntryByBarcode,
        variables: Variables$Query$FoodEntryByBarcode(barcode: barcode).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'foodEntryByBarcode');
    }

    final data = result.data;
    if (data == null) return null;

    return Query$FoodEntryByBarcode.fromJson(data).foodEntryByBarcode;
  }

  /// Fetches a food entry by ID.
  Future<Query$FoodEntryById$foodEntryById?> getFoodById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: documentNodeQueryFoodEntryById,
        variables: Variables$Query$FoodEntryById(id: id).toJson(),
      ),
    );

    if (result.hasException) {
      _handleException(result.exception!, 'foodEntryById');
    }

    final data = result.data;
    if (data == null) return null;

    return Query$FoodEntryById.fromJson(data).foodEntryById;
  }
}
