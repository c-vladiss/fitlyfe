import 'package:flutter/foundation.dart';
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
  final List<Food> _foods = [];

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

  static final List<Food> presets = [
    Food(
      id: 'p1',
      name: 'Chicken Breast',
      calories: 165,
      protein: 31.0,
      carbs: 0.0,
      fats: 3.6,
      kcalPer100g: 165,
      micronutrients: {'iron': 1.0, 'magnesium': 29.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p2',
      name: 'Brown Rice (Cooked)',
      calories: 111,
      protein: 2.6,
      carbs: 23.0,
      fats: 0.9,
      kcalPer100g: 111,
      micronutrients: {'magnesium': 43.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p3',
      name: 'Avocado',
      calories: 160,
      protein: 2.0,
      carbs: 8.5,
      fats: 14.7,
      kcalPer100g: 160,
      micronutrients: {'vitamin_c': 10.0, 'magnesium': 29.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p4',
      name: 'Oatmeal',
      calories: 389,
      protein: 16.9,
      carbs: 66.3,
      fats: 6.9,
      kcalPer100g: 389,
      micronutrients: {'iron': 4.7, 'magnesium': 177.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p5',
      name: 'Boiled Egg (Large)',
      calories: 155,
      protein: 13.0,
      carbs: 1.1,
      fats: 11.0,
      kcalPer100g: 155,
      micronutrients: {'vitamin_a': 520.0, 'iron': 1.2},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p6',
      name: 'Salmon Fillet',
      calories: 208,
      protein: 20.0,
      carbs: 0.0,
      fats: 13.0,
      kcalPer100g: 208,
      micronutrients: {'vitamin_d': 11.0, 'magnesium': 27.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p7',
      name: 'Greek Yogurt',
      calories: 59,
      protein: 10.0,
      carbs: 3.6,
      fats: 0.4,
      kcalPer100g: 59,
      micronutrients: {'calcium': 110.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p8',
      name: 'Banana',
      calories: 89,
      protein: 1.1,
      carbs: 22.8,
      fats: 0.3,
      kcalPer100g: 89,
      micronutrients: {'vitamin_c': 8.7, 'magnesium': 27.0},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p9',
      name: 'Spinach (Raw)',
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fats: 0.4,
      kcalPer100g: 23,
      micronutrients: {'vitamin_a': 9377.0, 'vitamin_c': 28.1, 'iron': 2.7},
      dateAdded: DateTime.now(),
    ),
    Food(
      id: 'p10',
      name: 'Almonds',
      calories: 579,
      protein: 21.0,
      carbs: 22.0,
      fats: 50.0,
      kcalPer100g: 579,
      micronutrients: {'calcium': 264.0, 'magnesium': 270.0},
      dateAdded: DateTime.now(),
    ),
  ];

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

  final Set<String> _favoritePresetIds = {};

  Set<String> get favoritePresetIds => _favoritePresetIds;

  void toggleFavoritePreset(String id) {
    if (_favoritePresetIds.contains(id)) {
      _favoritePresetIds.remove(id);
    } else {
      _favoritePresetIds.add(id);
    }
    notifyListeners();
  }

  final Set<String> _favoriteRecipeIds = {};

  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;

  void toggleFavoriteRecipe(String id) {
    if (_favoriteRecipeIds.contains(id)) {
      _favoriteRecipeIds.remove(id);
    } else {
      _favoriteRecipeIds.add(id);
    }
    notifyListeners();
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

    // Cascade rename the mealType of foods that were under the old meal name for ALL days
    for (int i = 0; i < _foods.length; i++) {
        var f = _foods[i];
        if (f.mealType == oldMealName) {
           _foods[i] = f.copyWith(mealType: newMeal.name);
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

    // 2. Cascade rename the mealType of foods that were under the old meal name for that day
    for (int i = 0; i < _foods.length; i++) {
        var f = _foods[i];
        if (f.dateAdded.year == date.year &&
            f.dateAdded.month == date.month &&
            f.dateAdded.day == date.day &&
            f.mealType == oldMealName) {
                 _foods[i] = Food(
                    id: f.id,
                    name: f.name,
                    calories: f.calories,
                    protein: f.protein,
                    carbs: f.carbs,
                    fats: f.fats,
                    kcalPer100g: f.kcalPer100g,
                    micronutrients: f.micronutrients,
                    dateAdded: f.dateAdded,
                    mealType: newMeal.name,
                 );
            }
    }
    notifyListeners();
  }

  void reorderMeals(DateTime date, int oldIndex, int newIndex) {
    final meals = getMealsForDate(date).toList();
    final MealInfo meal = meals.removeAt(oldIndex);
    meals.insert(newIndex, meal);
    setMealsForDate(date, meals);
  }

  List<Food> get foods => _foods;

  List<Food> get todayFoods {
    return _foods.where((food) {
      return food.dateAdded.year == _selectedDate.year &&
          food.dateAdded.month == _selectedDate.month &&
          food.dateAdded.day == _selectedDate.day;
    }).toList();
  }

  double get todayCalories {
    // Prefer backend data if available
    if (_dailyNutritionData != null) {
      return (_dailyNutritionData!.totalCalories ?? 0).toDouble();
    }
    return todayFoods.fold(0.0, (sum, food) => sum + food.calories);
  }

  double get todayProtein {
    if (_dailyNutritionData != null) {
      return _dailyNutritionData!.proteinG ?? 0.0;
    }
    return todayFoods.fold(0.0, (sum, food) => sum + food.protein);
  }

  double get todayCarbs {
    if (_dailyNutritionData != null) {
      return _dailyNutritionData!.carbsG ?? 0.0;
    }
    return todayFoods.fold(0.0, (sum, food) => sum + food.carbs);
  }

  double get todayFats {
    if (_dailyNutritionData != null) {
      return _dailyNutritionData!.fatG ?? 0.0;
    }
    return todayFoods.fold(0.0, (sum, food) => sum + food.fats);
  }

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

  /// Adds a food entry to a meal on the backend.
  Future<bool> addFoodToMeal({
    required String foodEntryId,
    required String mealType,
    required double quantityG,
    DateTime? date,
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

      debugPrint('Added meal entry: ${result.entry.id}');
      return true;
    } catch (e) {
      debugPrint('Error adding food to meal: $e');
      _error = 'Failed to add food';
      notifyListeners();
      return false;
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
  Future<FoodSearchResult?> searchFoods(String query, {int? limit}) async {
    try {
      return await _graphQLService.searchFoodCatalog(
        query: query,
        limit: limit ?? 20,
      );
    } catch (e) {
      debugPrint('Error searching foods: $e');
      return null;
    }
  }

  /// Looks up a food by barcode.
  Future<dynamic> lookupBarcode(String barcode) async {
    try {
      return await _graphQLService.getFoodByBarcode(barcode);
    } catch (e) {
      debugPrint('Error looking up barcode: $e');
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ── Local-only methods (kept for backward compatibility) ────────────────

  void addFood(Food food) {
    _foods.add(food);
    _updateMicronutrients(food.micronutrients);
    notifyListeners();
  }

  void addVitamin(String type, double amount) {
    if (_dailyMicronutrients.containsKey(type)) {
      _dailyMicronutrients[type] = (_dailyMicronutrients[type] ?? 0) + amount;
      notifyListeners();
    }
  }

  void removeFood(String foodId) {
    final food = _foods.firstWhere((f) => f.id == foodId);
    _foods.removeWhere((f) => f.id == foodId);
    _removeMicronutrients(food.micronutrients);
    notifyListeners();
  }

  void _updateMicronutrients(Map<String, double> micronutrients) {
    micronutrients.forEach((key, value) {
      if (_dailyMicronutrients.containsKey(key)) {
        _dailyMicronutrients[key] = (_dailyMicronutrients[key] ?? 0) + value;
      }
    });
  }

  void _removeMicronutrients(Map<String, double> micronutrients) {
    micronutrients.forEach((key, value) {
      if (_dailyMicronutrients.containsKey(key)) {
        _dailyMicronutrients[key] = (_dailyMicronutrients[key] ?? 0) - value;
        if (_dailyMicronutrients[key]! < 0) {
          _dailyMicronutrients[key] = 0;
        }
      }
    });
  }

  void resetDailyMicronutrients() {
    _dailyMicronutrients.forEach((key, value) {
      _dailyMicronutrients[key] = 0.0;
    });
    notifyListeners();
  }
}
