import 'package:flutter/foundation.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';

class MealInfo {
  final String name;
  final String emoji;
  final int goalCals;

  MealInfo(this.name, this.emoji, this.goalCals);
}

class NutritionProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;

  // Loading/error states
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Backend data cache
  DailyNutritionResult? _dailyNutritionData;
  DailyNutritionResult? get dailyNutritionData => _dailyNutritionData;

  NutritionProvider({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService();


  static const Map<String, double> micronutrientRDIs = {
    'vitamin_a': 900.0,    // mcg
    'vitamin_c': 90.0,     // mg
    'vitamin_d': 20.0,     // mcg
    'calcium': 1000.0,     // mg
    'iron': 18.0,          // mg
    'magnesium': 420.0,    // mg
  };

  final Map<String, double> _dailyMicronutrients = {
    'vitamin_a': 0.0,
    'vitamin_c': 0.0,
    'vitamin_d': 0.0,
    'calcium': 0.0,
    'iron': 0.0,
    'magnesium': 0.0,
  };

  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    // Load nutrition data for the new date
    loadDailyNutrition();
  }

  // Catalog foods the user starred or logged, for the Favorites / Recent tabs.
  // Kept in memory for the session.
  final Map<String, Food> _favoriteFoods = {};
  final List<Food> _recentFoods = [];

  List<Food> get favoriteFoods => _favoriteFoods.values.toList();

  /// Most recently logged first, one entry per catalog food.
  List<Food> get recentFoods => List.unmodifiable(_recentFoods);

  bool isFavorite(String foodId) => _favoriteFoods.containsKey(foodId);

  void toggleFavorite(Food food) {
    if (_favoriteFoods.remove(food.id) == null) {
      _favoriteFoods[food.id] = food;
    }
    notifyListeners();
  }

  void _rememberRecent(Food food) {
    _recentFoods
      ..removeWhere((f) => f.id == food.id)
      ..insert(0, food);
    if (_recentFoods.length > 30) _recentFoods.removeLast();
  }

  final Map<String, List<MealInfo>> _customMealsPerDay = {};

  List<MealInfo> _defaultMeals = [
    MealInfo('Breakfast', '\u2615', 600),
    MealInfo('Lunch', '\uD83C\uDF72', 800),
    MealInfo('Dinner', '\uD83E\uDD57', 500),
    MealInfo('Snacks', '\uD83C\uDF4E', 100),
  ];

  void setDefaultMeals(List<MealInfo> meals) {
    _defaultMeals = meals;
    notifyListeners();
  }

  List<MealInfo> getMealsForDate(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    if (_customMealsPerDay.containsKey(key)) {
      return _customMealsPerDay[key]!;
    }
    return List.from(_defaultMeals);
  }

  void setMealsForDate(DateTime date, List<MealInfo> meals) {
    final key = '${date.year}-${date.month}-${date.day}';
    _customMealsPerDay[key] = meals;
    notifyListeners();
  }

  void deleteMealGlobally(String mealName) {
    _defaultMeals.removeWhere((m) => m.name == mealName);
    for (var key in _customMealsPerDay.keys) {
      _customMealsPerDay[key]!.removeWhere((m) => m.name == mealName);
    }
    notifyListeners();
  }

  void addMealGlobally(MealInfo meal) {
    if (!_defaultMeals.any((m) => m.name == meal.name)) {
      _defaultMeals.add(meal);
    }
    for (var key in _customMealsPerDay.keys) {
      if (!_customMealsPerDay[key]!.any((m) => m.name == meal.name)) {
        _customMealsPerDay[key]!.add(meal);
      }
    }
    notifyListeners();
  }

  void updateMealGlobally(String oldMealName, MealInfo newMeal) {
    int defaultIndex = _defaultMeals.indexWhere((m) => m.name == oldMealName);
    if (defaultIndex != -1) {
      _defaultMeals[defaultIndex] = newMeal;
    } else {
      _defaultMeals.add(newMeal);
    }

    for (var key in _customMealsPerDay.keys) {
      var meals = _customMealsPerDay[key]!;
      int idx = meals.indexWhere((m) => m.name == oldMealName);
      if (idx != -1) {
        meals[idx] = newMeal;
      } else {
        meals.add(newMeal);
      }
    }
    notifyListeners();
  }

  void deleteMealForDate(DateTime date, String mealName) {
    final meals = getMealsForDate(date).toList();
    meals.removeWhere((m) => m.name == mealName);
    setMealsForDate(date, meals);
  }

  void addMealForDate(DateTime date, MealInfo meal) {
    final meals = getMealsForDate(date).toList();
    meals.add(meal);
    setMealsForDate(date, meals);
  }

  void updateMealForDate(DateTime date, String oldMealName, MealInfo newMeal) {
    // 1. Update the meal list (keep position)
    final meals = getMealsForDate(date).toList();
    final index = meals.indexWhere((m) => m.name == oldMealName);
    if (index != -1) {
      meals[index] = newMeal;
      setMealsForDate(date, meals);
    } else {
      meals.add(newMeal);
      setMealsForDate(date, meals);
    }

    notifyListeners();
  }

  void reorderMeals(DateTime date, int oldIndex, int newIndex) {
    final meals = getMealsForDate(date).toList();
    final MealInfo meal = meals.removeAt(oldIndex);
    meals.insert(newIndex, meal);
    setMealsForDate(date, meals);
  }

  /// Food logged on the selected day, from the backend. Each item's [Food.id]
  /// is the meal entry id and [Food.mealType] the meal it was logged in.
  List<Food> get todayFoods {
    final day = _dailyNutritionData;
    if (day == null) return const [];
    return [
      for (final meal in day.meals)
        for (final entry in meal.entries)
          Food(
            id: entry.id,
            name: entry.foodEntry.name,
            calories: (entry.calories ?? 0).toDouble(),
            protein: entry.proteinG ?? 0,
            carbs: entry.carbsG ?? 0,
            fats: entry.fatG ?? 0,
            dateAdded: _selectedDate,
            mealType: meal.mealType,
            servingSizeG: entry.quantityG,
          ),
    ];
  }

  double get todayCalories =>
      (_dailyNutritionData?.totalCalories ?? 0).toDouble();

  double get todayProtein => _dailyNutritionData?.proteinG ?? 0.0;

  double get todayCarbs => _dailyNutritionData?.carbsG ?? 0.0;

  double get todayFats => _dailyNutritionData?.fatG ?? 0.0;

  // Daily goals from backend
  int get dailyCalorieGoal {
    return _dailyNutritionData?.goals.totalCalories ?? 2000;
  }

  double get dailyProteinGoal {
    return _dailyNutritionData?.goals.totalProteinG ?? 150.0;
  }

  double get dailyCarbsGoal {
    return _dailyNutritionData?.goals.totalCarbsG ?? 250.0;
  }

  double get dailyFatGoal {
    return _dailyNutritionData?.goals.totalFatG ?? 65.0;
  }

  Map<String, double> get dailyMicronutrients => _dailyMicronutrients;

  Map<String, double> get micronutrientPercentages {
    final Map<String, double> percentages = {};
    _dailyMicronutrients.forEach((key, value) {
      final rdi = micronutrientRDIs[key] ?? 1.0;
      percentages[key] = (value / rdi).clamp(0.0, 1.0);
    });
    return percentages;
  }

  // ── Backend Integration ─────────────────────────────────────────────────

  /// Loads daily nutrition data from the backend for the selected date.
  Future<void> loadDailyNutrition() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr = _formatDate(_selectedDate);
      _dailyNutritionData = await _graphQLService.getDailyNutrition(dateStr);
      _error = null;
    } on BackendNetworkException catch (e) {
      debugPrint('Network error loading nutrition: $e');
      _error = 'Could not reach server';
    } on BackendSyncException catch (e) {
      debugPrint('Sync error loading nutrition: $e');
      _error = 'Failed to load nutrition data';
    } catch (e) {
      debugPrint('Error loading nutrition: $e');
      _error = 'An error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs [quantityG] grams of a catalog food in a meal on the backend.
  /// Returns the new meal entry's id, or null if it could not be saved.
  Future<String?> addFoodToMeal({
    required String foodEntryId,
    required String mealType,
    required double quantityG,
    DateTime? date,
    Food? food,
  }) async {
    final targetDate = date ?? _selectedDate;
    final dateStr = _formatDate(targetDate);

    try {
      final result = await _graphQLService.addMealEntry(
        date: dateStr,
        mealType: mealType,
        foodEntryId: foodEntryId,
        quantityG: quantityG,
      );

      // Refresh the daily nutrition data to reflect the new entry
      await loadDailyNutrition();

      if (food != null) _rememberRecent(food);
      notifyListeners();
      return result.entry.id;
    } catch (e) {
      debugPrint('Error adding food to meal: $e');
      _error = 'Failed to add food';
      notifyListeners();
      return null;
    }
  }

  /// Updates a meal entry on the backend.
  Future<bool> updateMealEntry({
    required String entryId,
    double? quantityG,
    String? foodEntryId,
  }) async {
    try {
      await _graphQLService.updateMealEntry(
        entryId: entryId,
        quantityG: quantityG,
        foodEntryId: foodEntryId,
      );

      // Refresh the daily nutrition data
      await loadDailyNutrition();
      return true;
    } catch (e) {
      debugPrint('Error updating meal entry: $e');
      _error = 'Failed to update entry';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a meal entry from the backend.
  Future<bool> deleteMealEntry(String entryId) async {
    try {
      final success = await _graphQLService.deleteMealEntry(entryId);
      if (success) {
        // Refresh the daily nutrition data
        await loadDailyNutrition();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting meal entry: $e');
      _error = 'Failed to delete entry';
      notifyListeners();
      return false;
    }
  }

  /// Searches the food catalog.
  Future<FoodSearchResult?> searchFoods(
    String query, {
    int? limit,
    List<Enum$FoodEntryType>? types,
  }) async {
    try {
      return await _graphQLService.searchFoodCatalog(
        query: query,
        limit: limit ?? 20,
        types: types,
      );
    } catch (e) {
      debugPrint('Error searching foods: $e');
      return null;
    }
  }

  /// Looks up a product by barcode. Returns null if it is unknown or the
  /// lookup failed.
  Future<Food?> lookupBarcode(String barcode) async {
    try {
      final product = await _graphQLService.getFoodByBarcode(barcode);
      if (product == null) return null;
      return catalogFood(
        id: product.id,
        name: product.name,
        brand: product.brand,
        servingSizeG: product.servingSizeG,
        caloriesPer100g: product.caloriesPer100g,
        proteinPer100g: product.proteinPer100g,
        carbsPer100g: product.carbsPer100g,
        fatPer100g: product.fatPer100g,
      );
    } catch (e) {
      debugPrint('Error looking up barcode: $e');
      return null;
    }
  }

  /// A catalog item as a [Food] whose nutrition values are per 100 g.
  static Food catalogFood({
    required String id,
    required String name,
    String? brand,
    double? servingSizeG,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
  }) {
    return Food(
      id: id,
      name: name,
      brand: brand,
      calories: caloriesPer100g ?? 0,
      protein: proteinPer100g ?? 0,
      carbs: carbsPer100g ?? 0,
      fats: fatPer100g ?? 0,
      kcalPer100g: caloriesPer100g ?? 0,
      servingSizeG: servingSizeG,
      dateAdded: DateTime.now(),
    );
  }

  /// Converts a catalog search result item into a [Food] (per 100 g).
  static Food foodFromSearchItem(FoodEntry item) => catalogFood(
        id: item.id,
        name: item.name,
        brand: item.brand,
        servingSizeG: item.servingSizeG,
        caloriesPer100g: item.caloriesPer100g,
        proteinPer100g: item.proteinPer100g,
        carbsPer100g: item.carbsPer100g,
        fatPer100g: item.fatPer100g,
      );

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ── Vitamins & supplements (tracked on the device only) ────────────────

  void addVitamin(String type, double amount) {
    if (_dailyMicronutrients.containsKey(type)) {
      _dailyMicronutrients[type] = (_dailyMicronutrients[type] ?? 0) + amount;
      notifyListeners();
    }
  }

  void resetDailyMicronutrients() {
    _dailyMicronutrients.forEach((key, value) {
      _dailyMicronutrients[key] = 0.0;
    });
    notifyListeners();
  }
}
