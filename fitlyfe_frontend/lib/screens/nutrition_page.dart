import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/micronutrient_card.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/utils/meal_icon_mapping.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitlyfe_frontend/screens/nutrition_details_page.dart';
import 'package:fitlyfe_frontend/screens/meal_settings_page.dart';
import 'package:fitlyfe_frontend/screens/food_details_page.dart';
import 'package:fitlyfe_frontend/screens/barcode_scanner_page.dart';
import 'package:intl/intl.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  @override
  void initState() {
    super.initState();
    // Logged food lives on the backend; fetch the selected day when the tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NutritionProvider>(context, listen: false).loadDailyNutrition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final l10n = AppLocalizations.of(context);
    final user = appState.currentUser;

    final caloriesConsumed = nutritionProvider.todayCalories;
    final caloriesGoal = user.dailyCalorieGoal;

    // Calculate Macro Goals (30% Protein, 40% Carbs, 30% Fats)
    final proteinGoal = (caloriesGoal * 0.30) / 4;
    final carbsGoal = (caloriesGoal * 0.40) / 4;
    final fatsGoal = (caloriesGoal * 0.30) / 9;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.nutrition,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Date Selector
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final selectedDate = nutritionProvider.selectedDate;
                  final isToday = selectedDate.year == now.year &&
                      selectedDate.month == now.month &&
                      selectedDate.day == now.day;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryText, size: 20),
                        onPressed: () {
                          nutritionProvider.setSelectedDate(
                            selectedDate.subtract(const Duration(days: 1))
                          );
                        },
                      ),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios, 
                          color: isToday 
                              ? AppTheme.secondaryText.withValues(alpha: 0.5) 
                              : AppTheme.primaryText, 
                          size: 20,
                        ),
                        onPressed: isToday 
                            ? null 
                            : () {
                                nutritionProvider.setSelectedDate(
                                  selectedDate.add(const Duration(days: 1))
                                );
                              },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Summary Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NutritionDetailsPage(
                            caloriesConsumed: caloriesConsumed,
                            caloriesGoal: caloriesGoal,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    // Top Row: Remaining Chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Center: Remaining Chart
                        _CalorieMacroChart(
                          caloriesGoal: caloriesGoal,
                          caloriesConsumed: caloriesConsumed,
                          protein: nutritionProvider.todayProtein,
                          carbs: nutritionProvider.todayCarbs,
                          fats: nutritionProvider.todayFats,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Bottom Row: Macros
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMiniMacroBar('Carbs', nutritionProvider.todayCarbs, carbsGoal, AppTheme.accentGreen),
                        _buildMiniMacroBar('Protein', nutritionProvider.todayProtein, proteinGoal, AppTheme.accentBlue),
                        _buildMiniMacroBar('Fat', nutritionProvider.todayFats, fatsGoal, AppTheme.accentOrange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Nutrition Categories Section
                  Text(
                    'Nutrition',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildReorderableMeals(context, nutritionProvider, l10n),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealSettingsPage(
                                date: nutritionProvider.selectedDate,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentGreen),
                        label: const Text(
                          'Add Meal Category',
                          style: TextStyle(color: AppTheme.accentGreen, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Micronutrients
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.micronutrients,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVitaminDialog(context, l10n),
                    icon: const Icon(Icons.medication, size: 20),
                    label: Text(l10n.addVitamin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: AppTheme.primaryText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MicronutrientCard(
                percentages: nutritionProvider.micronutrientPercentages,
                rawValues: nutritionProvider.dailyMicronutrients,
                rdis: NutritionProvider.micronutrientRDIs,
                nutrients: NutritionProvider.micronutrientRDIs,
              ),
              const SizedBox(height: 32),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableMeals(BuildContext context, NutritionProvider provider, AppLocalizations l10n) {
    final meals = provider.getMealsForDate(provider.selectedDate);

    // Calculate adjusted goals based on calorie carry-over overages
    final adjustedGoals = <int>[];
    int carryOver = 0;
    
    for (int i = 0; i < meals.length; i++) {
      final meal = meals[i];
      final foods = provider.todayFoods.where((f) => f.mealType == meal.name).toList();
      final double consumed = foods.fold(0.0, (sum, food) => sum + food.calories);
      
      int currentGoal = meal.goalCals - carryOver;
      if (currentGoal < 0) {
        carryOver = -currentGoal;
        currentGoal = 0;
      } else {
        carryOver = 0;
      }
      adjustedGoals.add(currentGoal);
      
      if (consumed > currentGoal) {
        carryOver += (consumed - currentGoal).toInt();
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: meals.length,
        onReorder: (oldIndex, newIndex) {
          int adjustedNewIndex = newIndex;
          if (oldIndex < newIndex) {
            adjustedNewIndex -= 1;
          }
          provider.reorderMeals(provider.selectedDate, oldIndex, adjustedNewIndex);
        },
        itemBuilder: (context, index) {
          final meal = meals[index];
          final adjustedGoal = adjustedGoals[index];
          return Container(
            key: ValueKey(meal.name),
            child: Column(
              children: [
                _MealSection(
                  index: index,
                  mealName: meal.name,
                  emojiStr: meal.emoji,
                  goalCals: adjustedGoal,
                  foods: provider.todayFoods.where((f) => f.mealType == meal.name).toList(),
                  onAddTap: () => _showAddFoodDialog(context, l10n, mealType: meal.name),
                  onMealTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealSettingsPage(
                          date: provider.selectedDate,
                          currentMeal: meal,
                        ),
                      ),
                    );
                  },
                ),
                if (index < meals.length - 1)
                  Divider(color: AppTheme.secondaryText.withValues(alpha: 0.1), height: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniMacroBar(String label, double value, double goal, Color color) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppTheme.secondaryText.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${value.toInt()} / ${goal.toInt()} g',
          style: const TextStyle(color: AppTheme.primaryText, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, AppLocalizations l10n, {String? mealType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodSearchSheet(mealType: mealType),
      ),
    );
  }

  void _showAddVitaminDialog(BuildContext context, AppLocalizations l10n) {
    String selectedType = NutritionProvider.micronutrientRDIs.keys.first;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(l10n.addVitamin),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: AppTheme.cardBackground,
                decoration: InputDecoration(
                  labelText: l10n.vitaminType,
                  labelStyle: const TextStyle(color: AppTheme.secondaryText),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.secondaryText.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentGreen),
                  ),
                ),
                items: NutritionProvider.micronutrientRDIs.keys.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  labelStyle: const TextStyle(color: AppTheme.secondaryText),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.secondaryText.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentGreen),
                  ),
                  suffixText:
                      selectedType.contains('vitamin_a') ||
                          selectedType.contains('vitamin_d')
                      ? 'mcg'
                      : 'mg',
                  suffixStyle: const TextStyle(color: AppTheme.secondaryText),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  Provider.of<NutritionProvider>(
                    context,
                    listen: false,
                  ).addVitamin(selectedType, amount);
                }
                Navigator.pop(context);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFoodSearchSheet extends StatefulWidget {
  final String? mealType;

  const AddFoodSearchSheet({super.key, this.mealType});

  @override
  State<AddFoodSearchSheet> createState() => _AddFoodSearchSheetState();
}

/// Search tabs of the add-food screen.
enum _FoodTab { search, recent, favorites }

/// What the category boxes filter on, mapped to catalog entry types.
enum _FoodCategory {
  foods('Foods', Icons.restaurant, AppTheme.accentOrange,
      [Enum$FoodEntryType.FOOD, Enum$FoodEntryType.PRODUCT]),
  recipes('Recipes', Icons.menu_book, AppTheme.accentYellow,
      [Enum$FoodEntryType.RECIPE]);

  final String label;
  final IconData icon;
  final Color color;
  final List<Enum$FoodEntryType> types;

  const _FoodCategory(this.label, this.icon, this.color, this.types);
}

class _AddFoodSearchSheetState extends State<AddFoodSearchSheet> {
  /// Searches shorter than this return too much noise to be useful.
  static const minQueryLength = 2;
  static const _debounce = Duration(milliseconds: 350);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  int _searchGeneration = 0;

  List<Food> _results = [];
  bool _isSearching = false;
  bool _searchFailed = false;

  // Foods logged from this screen, shown in the "Just Added" sheet.
  // Their id is the backend meal entry id, so they can be undone.
  final List<Food> _sessionAddedFoods = [];
  final Set<String> _animatingFoodIds = {};
  bool _justAddedAnimation = false;

  _FoodCategory _selectedCategory = _FoodCategory.foods;
  _FoodTab _selectedTab = _FoodTab.search;

  String get _mealType => widget.mealType ?? 'Snacks';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    if (_selectedTab != _FoodTab.search) {
      setState(() {}); // Recent / Favorites filter locally
      return;
    }
    _debounceTimer = Timer(_debounce, _search);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    final generation = ++_searchGeneration;
    if (query.length < minQueryLength) {
      setState(() {
        _results = [];
        _isSearching = false;
        _searchFailed = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final provider = Provider.of<NutritionProvider>(context, listen: false);
    final result = await provider.searchFoods(
      query,
      types: _selectedCategory.types,
      limit: 25,
    );
    // Ignore responses to queries the user has already typed past
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _isSearching = false;
      _searchFailed = result == null;
      _results =
          result?.items.map(NutritionProvider.foodFromSearchItem).toList() ?? [];
    });
  }

  /// Foods to show for the current tab and search text.
  List<Food> _visibleFoods(NutritionProvider provider) {
    if (_selectedTab == _FoodTab.search) return _results;
    final query = _searchController.text.trim().toLowerCase();
    final base = _selectedTab == _FoodTab.recent
        ? provider.recentFoods
        : provider.favoriteFoods;
    return base.where((f) => f.name.toLowerCase().contains(query)).toList();
  }

  /// Logs one serving (or 100 g when the serving size is unknown).
  Future<void> _quickAdd(Food food) async {
    final grams = food.servingSizeG ?? 100;
    final provider = Provider.of<NutritionProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _animatingFoodIds.add(food.id));

    final entryId = await provider.addFoodToMeal(
      foodEntryId: food.id,
      mealType: _mealType,
      quantityG: grams,
      food: food,
    );
    if (!mounted) return;

    if (entryId == null) {
      setState(() => _animatingFoodIds.remove(food.id));
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add the food. Please try again.')),
      );
      return;
    }
    setState(() => _sessionAddedFoods.add(_loggedFood(food, entryId, grams)));
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _animatingFoodIds.remove(food.id));
    });
    _triggerJustAddedAnimation();
  }

  /// A logged entry for the "Just Added" list, with totals for [grams].
  static Food _loggedFood(Food food, String entryId, double grams) {
    final ratio = grams / 100;
    return food.copyWith(
      id: entryId,
      calories: food.calories * ratio,
      protein: food.protein * ratio,
      carbs: food.carbs * ratio,
      fats: food.fats * ratio,
    );
  }

  Future<void> _openDetails(Food food) async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsPage(food: food, mealType: _mealType),
      ),
    );
    if (added is Food && mounted) {
      setState(() => _sessionAddedFoods.add(added));
      _triggerJustAddedAnimation();
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (barcode is! String || !mounted) return;

    final provider = Provider.of<NutritionProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final food = await provider.lookupBarcode(barcode);
    if (!mounted) return;
    if (food == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('No product found for barcode $barcode')),
      );
      return;
    }
    await _openDetails(food);
  }

  void _triggerJustAddedAnimation() {
    setState(() => _justAddedAnimation = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _justAddedAnimation = false);
    });
  }

  Widget _buildCategoryBox(_FoodCategory category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _search();
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isSelected ? category.color.withValues(alpha: 0.2) : AppTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? category.color : Colors.transparent, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(category.icon, size: 28, color: category.color),
          ),
          const SizedBox(height: 8),
          Text(category.label, style: TextStyle(color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, _FoodTab tab) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = tab);
          if (tab == _FoodTab.search) _search();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text.trim();
    final String message;
    IconData icon = Icons.search_off;
    switch (_selectedTab) {
      case _FoodTab.recent:
        message = 'Foods you log will show up here.';
      case _FoodTab.favorites:
        message = 'Tap the star on a food to keep it here.';
      case _FoodTab.search:
        if (_searchFailed) {
          icon = Icons.cloud_off;
          message = 'Could not reach the food database. Check your connection and try again.';
        } else if (query.length < minQueryLength) {
          icon = Icons.search;
          message = 'Search thousands of foods, or scan a barcode.';
        } else {
          message = 'No ${_selectedCategory.label.toLowerCase()} found for "$query". Try another name or scan the barcode.';
        }
    }

    // Scrollable so long messages still fit on short screens / with the keyboard open
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.secondaryText),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionAddedFoods() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.secondaryText.withValues(alpha: 0.2), width: 1),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Just Added', style: TextStyle(color: AppTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _sessionAddedFoods.isEmpty
                      ? const Center(child: Text('No foods added yet', style: TextStyle(color: AppTheme.secondaryText)))
                      : ListView.separated(
                      itemCount: _sessionAddedFoods.length,
                      separatorBuilder: (context, index) => Divider(color: AppTheme.secondaryText.withValues(alpha: 0.1), height: 1),
                      itemBuilder: (context, index) {
                        final food = _sessionAddedFoods[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(food.name, style: const TextStyle(color: AppTheme.primaryText, fontSize: 16)),
                          subtitle: Text('${food.calories.round()} kcal', style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.accentOrange),
                            tooltip: 'Remove',
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final removed = await Provider.of<NutritionProvider>(context, listen: false)
                                  .deleteMealEntry(food.id);
                              if (!removed || !mounted) return;
                              setModalState(() => _sessionAddedFoods.remove(food));
                              setState(() {}); // trigger update in parent pill
                              if (_sessionAddedFoods.isEmpty) navigator.pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 160,
        leading: GestureDetector(
          onTap: _sessionAddedFoods.isNotEmpty ? _showSessionAddedFoods : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  transform: Matrix4.identity()..scaleByDouble(_justAddedAnimation ? 1.05 : 1.0, _justAddedAnimation ? 1.05 : 1.0, 1.0, 1.0),
                  transformAlignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _justAddedAnimation ? AppTheme.accentGreen.withValues(alpha: 0.2) : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _justAddedAnimation ? AppTheme.accentGreen : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _sessionAddedFoods.isEmpty ? 'Just Added' : 'Just Added (${_sessionAddedFoods.length})',
                    style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          widget.mealType ?? l10n.addFood,
          style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGreen, width: 1.5),
              ),
              child: TextField(
                key: const Key('foodSearchField'),
                controller: _searchController,
                style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'What did you have for ${widget.mealType?.toLowerCase() ?? 'meal'}?',
                  hintStyle: TextStyle(color: AppTheme.secondaryText.withValues(alpha: 0.8), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText, size: 24),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondaryText, size: 24),
                    tooltip: 'Scan barcode',
                    onPressed: _scanBarcode,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Categories row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryBox(_FoodCategory.foods),
                const SizedBox(width: 16),
                _buildCategoryBox(_FoodCategory.recipes),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildTab('Search', _FoodTab.search),
                  _buildTab('Recent', _FoodTab.recent),
                  _buildTab('Favorites', _FoodTab.favorites),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _showManualMenu
                ? _buildManualMenu()
                : (_filteredPresets.isEmpty)
                    ? _buildEmptyState(l10n)
                    : ListView.separated(
                        itemCount: foods.length,
                        separatorBuilder: (context, index) => Divider(color: AppTheme.secondaryText.withValues(alpha: 0.1), height: 1),
                        itemBuilder: (context, index) => _buildFoodTile(foods[index], provider),
                      ),
          ),

          // Bottom sticky "Done" button
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: AppTheme.backgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTile(Food food, NutritionProvider provider) {
    final serving = food.servingSizeG;
    final servingLabel = serving != null ? '1 serving (${_formatGrams(serving)} g)' : '100 g';
    final servingCalories = food.calories * (serving ?? 100) / 100;
    final isFav = provider.isFavorite(food.id);
    final isAnimating = _animatingFoodIds.contains(food.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(food.name, style: const TextStyle(color: AppTheme.primaryText, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(
        [if (food.brand != null && food.brand!.isNotEmpty) food.brand!, servingLabel].join(' • '),
        style: TextStyle(color: AppTheme.secondaryText.withValues(alpha: 0.8), fontSize: 12),
      ),
      onTap: () => _openDetails(food),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${servingCalories.round()} kcal', style: const TextStyle(color: AppTheme.primaryText, fontSize: 14)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => provider.toggleFavorite(food),
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? AppTheme.accentYellow : AppTheme.secondaryText.withValues(alpha: 0.5),
              size: 24,
              semanticLabel: isFav ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isAnimating ? null : () => _quickAdd(food),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAnimating ? AppTheme.accentGreen : Colors.transparent,
                border: Border.all(color: AppTheme.accentGreen, width: 1.5),
              ),
              child: Icon(
                isAnimating ? Icons.check : Icons.add,
                color: isAnimating ? AppTheme.backgroundColor : AppTheme.accentGreen,
                size: 18,
                semanticLabel: 'Add ${food.name}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatGrams(double grams) =>
      grams == grams.roundToDouble() ? grams.toInt().toString() : grams.toStringAsFixed(1);
}

class _CalorieMacroChart extends StatefulWidget {
  final double caloriesGoal;
  final double caloriesConsumed;
  final double protein;
  final double carbs;
  final double fats;

  const _CalorieMacroChart({
    required this.caloriesGoal,
    required this.caloriesConsumed,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  State<_CalorieMacroChart> createState() => _CalorieMacroChartState();
}

class _CalorieMacroChartState extends State<_CalorieMacroChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caloriesRemaining = (widget.caloriesGoal - widget.caloriesConsumed)
        .clamp(0.0, widget.caloriesGoal);
    final proteinCals = widget.protein * 4;
    final carbsCals = widget.carbs * 4;
    final fatsCals = widget.fats * 9;
    final totalMacroCals = proteinCals + carbsCals + fatsCals;
    
    final pPct = totalMacroCals > 0 ? (proteinCals / totalMacroCals * 100).round() : 0;
    final cPct = totalMacroCals > 0 ? (carbsCals / totalMacroCals * 100).round() : 0;
    final fPct = totalMacroCals > 0 ? (fatsCals / totalMacroCals * 100).round() : 0;

    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 65,
                startDegreeOffset: -90,
                sections: [
                  if (totalMacroCals == 0) // Show empty gray circle if no macros
                    PieChartSectionData(
                      value: 1,
                      color: AppTheme.secondaryText.withValues(alpha: 0.2),
                      radius: 10,
                      showTitle: false,
                    ),
                  // Protein Section (Index 0)
                  if (proteinCals > 0)
                    PieChartSectionData(
                      value: proteinCals,
                      color: (widget.caloriesConsumed > widget.caloriesGoal) ? Colors.redAccent : AppTheme.accentBlue,
                      radius: _touchedIndex == 0 ? 16 : 10,
                      showTitle: false,
                    ),
                  // Carbs Section (Index 1)
                  if (carbsCals > 0)
                    PieChartSectionData(
                      value: carbsCals,
                      color: (widget.caloriesConsumed > widget.caloriesGoal) ? Colors.redAccent : AppTheme.accentGreen,
                      radius: _touchedIndex == 1 ? 16 : 10,
                      showTitle: false,
                    ),
                  // Fats Section (Index 2)
                  if (fatsCals > 0)
                    PieChartSectionData(
                      value: fatsCals,
                      color: (widget.caloriesConsumed > widget.caloriesGoal) ? Colors.redAccent : AppTheme.accentOrange,
                      radius: _touchedIndex == 2 ? 16 : 10,
                      showTitle: false,
                    ),
                  if (caloriesRemaining > 0)
                    PieChartSectionData(
                      value: caloriesRemaining,
                      color: AppTheme.secondaryText.withValues(alpha: 0.2),
                      radius: 10,
                      showTitle: false,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_touchedIndex == -1 && (widget.caloriesConsumed > widget.caloriesGoal))
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  ),
                Text(
                  _touchedIndex == 0
                      ? '$pPct%'
                      : _touchedIndex == 1
                      ? '$cPct%'
                      : _touchedIndex == 2
                      ? '$fPct%'
                      : '${(widget.caloriesConsumed - widget.caloriesGoal).abs().toInt()}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (_touchedIndex == -1 && (widget.caloriesConsumed > widget.caloriesGoal)) ? 26 : null,
                    color: (_touchedIndex == -1 && (widget.caloriesConsumed > widget.caloriesGoal))
                        ? Colors.redAccent
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _touchedIndex == 0
                      ? l10n.protein
                      : _touchedIndex == 1
                      ? l10n.carbs
                      : _touchedIndex == 2
                      ? l10n.fats
                      : ((widget.caloriesConsumed > widget.caloriesGoal) ? 'Over Goal' : 'Remaining'),
                  style: TextStyle(
                    color: (_touchedIndex == -1 && (widget.caloriesConsumed > widget.caloriesGoal))
                        ? Colors.redAccent
                        : AppTheme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _MealSection extends StatelessWidget {
  final int index;
  final String mealName;
  final String emojiStr;
  final int goalCals;
  final List<Food> foods;
  final VoidCallback onAddTap;
  final VoidCallback onMealTap;

  const _MealSection({
    required this.index,
    required this.mealName,
    required this.emojiStr,
    required this.goalCals,
    required this.foods,
    required this.onAddTap,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    final double totalCals = foods.fold(0.0, (sum, food) => sum + food.calories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: MealIconMapping.buildIcon(emojiStr, size: 24),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onMealTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealName,
                          style: const TextStyle(color: AppTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalCals.toInt()} / $goalCals Cal',
                          style: const TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryText,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, color: AppTheme.backgroundColor, size: 24),
                ),
              ),
            ],
          ),
        ),
        if (foods.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: foods.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '- ${food.name}',
                        style: const TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                      ),
                    ),
                    Text(
                      '${food.calories.toInt()} kcal',
                      style: const TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'Remove ${food.name}',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final removed = await Provider.of<NutritionProvider>(
                          context,
                          listen: false,
                        ).deleteMealEntry(food.id);
                        if (!removed) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Could not remove the food. Please try again.')),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.drag_handle, color: AppTheme.secondaryText, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

