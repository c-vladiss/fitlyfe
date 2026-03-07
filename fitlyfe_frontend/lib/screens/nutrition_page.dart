import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/micronutrient_card.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/utils/meal_icon_mapping.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitlyfe_frontend/screens/nutrition_details_page.dart';
import 'package:fitlyfe_frontend/screens/meal_settings_page.dart';
import 'package:fitlyfe_frontend/screens/food_details_page.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:intl/intl.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final tp = Provider.of<TranslationProvider>(context);
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
                    tp.translate('nutrition'),
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
                    _buildReorderableMeals(context, nutritionProvider, tp),
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
                    tp.translate('micronutrients'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVitaminDialog(context, tp),
                    icon: const Icon(Icons.medication, size: 20),
                    label: Text(tp.translate('add_vitamin')),
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

  Widget _buildReorderableMeals(BuildContext context, NutritionProvider provider, TranslationProvider tp) {
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
                  onAddTap: () => _showAddFoodDialog(context, tp, mealType: meal.name),
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

  void _showAddFoodDialog(BuildContext context, TranslationProvider tp, {String? mealType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodSearchSheet(mealType: mealType),
      ),
    );
  }

  void _showAddVitaminDialog(BuildContext context, TranslationProvider tp) {
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
          title: Text(tp.translate('add_vitamin')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: AppTheme.cardBackground,
                decoration: InputDecoration(
                  labelText: tp.translate('vitamin_type'),
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
                  labelText: tp.translate('amount'),
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
                tp.translate('cancel'),
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
              child: Text(tp.translate('add')),
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

class _AddFoodSearchSheetState extends State<AddFoodSearchSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _searchController = TextEditingController();

  List<Food> _filteredPresets = NutritionProvider.presets;
  bool _showManualMenu = false;
  List<Food> _sessionAddedFoods = [];
  final Set<String> _animatingFoodIds = {};
  bool _justAddedAnimation = false;

  String _selectedCategory = 'Foods';
  String _selectedTab = 'Frequent';

  static final _mockMeals = [
    Food(id: 'm1', name: 'Chicken & Rice combo', calories: 450, protein: 40, carbs: 50, fats: 10, dateAdded: DateTime.now()),
    Food(id: 'm2', name: 'Avocado Toast & Eggs', calories: 350, protein: 20, carbs: 30, fats: 15, dateAdded: DateTime.now()),
  ];
  static final _mockRecipes = [
    Food(id: 'r1', name: 'Protein Pancakes', calories: 400, protein: 35, carbs: 45, fats: 8, dateAdded: DateTime.now()),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPresets);
  }

  void _filterPresets() {
    final query = _searchController.text.toLowerCase();
    
    // Safety check incase Provider isn't ready in early initState callbacks
    if (!mounted) return;
    final provider = Provider.of<NutritionProvider>(context, listen: false);

    List<Food> baseList;
    if (_selectedTab == 'Recent') {
      final recentNames = <String>{};
      final recentList = <Food>[];
      for (var f in provider.foods.reversed) {
        if (!recentNames.contains(f.name)) {
          recentNames.add(f.name);
          recentList.add(f);
        }
      }
      baseList = recentList;
    } else {
      if (_selectedCategory == 'Foods') {
        baseList = NutritionProvider.presets;
      } else if (_selectedCategory == 'Meals') {
        baseList = _mockMeals;
      } else {
        baseList = _mockRecipes;
      }
    }

    if (_selectedTab == 'Favorites') {
      baseList = baseList.where((p) => provider.favoritePresetIds.contains(p.id)).toList();
    }

    setState(() {
      _filteredPresets = baseList
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addFood(Food baseFood) {
    final food = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: baseFood.name,
      calories: baseFood.kcalPer100g ?? baseFood.calories,
      protein: baseFood.protein,
      carbs: baseFood.carbs,
      fats: baseFood.fats,
      micronutrients: baseFood.micronutrients,
      dateAdded: Provider.of<NutritionProvider>(context, listen: false).selectedDate,
      mealType: widget.mealType,
    );
    Provider.of<NutritionProvider>(context, listen: false).addFood(food);
    
    setState(() {
      _sessionAddedFoods.add(food);
      _animatingFoodIds.add(baseFood.id);
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _animatingFoodIds.remove(baseFood.id));
      }
    });

    _triggerJustAddedAnimation();
  }

  void _triggerJustAddedAnimation() {
    setState(() => _justAddedAnimation = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _justAddedAnimation = false);
    });
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.secondaryText, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCategoryBox(String label, IconData iconData, Color iconColor) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          _filterPresets();
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isSelected ? iconColor.withValues(alpha: 0.2) : AppTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? iconColor : Colors.transparent, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 28, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
            _filterPresets();
          });
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

  Widget _buildEmptyState(TranslationProvider tp) {
    String categoryLabel = _selectedCategory.toLowerCase();
    String emptyMessage = 'The food you are searching is not in the database.';
    bool showManualButton = false;

    if (_selectedTab == 'Recent') {
      emptyMessage = 'There are no recent $categoryLabel added.';
    } else if (_selectedTab == 'Favorites') {
      emptyMessage = 'There are no favorites $categoryLabel.';
    } else if (_selectedCategory != 'Foods') {
      emptyMessage = 'No $categoryLabel found.';
    } else {
      showManualButton = true;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppTheme.secondaryText),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
            ),
            if (showManualButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _showManualMenu = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Manually', style: TextStyle(color: AppTheme.backgroundColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryText),
                onPressed: () => setState(() => _showManualMenu = false),
              ),
              const Text('Manual Entry', style: TextStyle(color: AppTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDarkTextField(controller: _nameController, hintText: 'Food Name'),
          const SizedBox(height: 16),
          _buildDarkTextField(controller: _caloriesController, hintText: 'Calories', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDarkTextField(controller: _proteinController, hintText: 'Protein (g)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: _buildDarkTextField(controller: _carbsController, hintText: 'Carbs (g)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: _buildDarkTextField(controller: _fatsController, hintText: 'Fats (g)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty) return;
              final food = Food(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                calories: double.tryParse(_caloriesController.text) ?? 0,
                protein: double.tryParse(_proteinController.text) ?? 0,
                carbs: double.tryParse(_carbsController.text) ?? 0,
                fats: double.tryParse(_fatsController.text) ?? 0,
                micronutrients: const {},
                dateAdded: Provider.of<NutritionProvider>(context, listen: false).selectedDate,
                mealType: widget.mealType,
              );
              Provider.of<NutritionProvider>(context, listen: false).addFood(food);
              setState(() {
                _sessionAddedFoods.add(food);
                _showManualMenu = false;
                _nameController.clear();
                _caloriesController.clear();
                _proteinController.clear();
                _carbsController.clear();
                _fatsController.clear();
              });
              _triggerJustAddedAnimation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Food', style: TextStyle(color: AppTheme.backgroundColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
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
                          subtitle: Text('${food.calories.toInt()} kcal', style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.accentOrange),
                            onPressed: () {
                              Provider.of<NutritionProvider>(context, listen: false).removeFood(food.id);
                              setModalState(() => _sessionAddedFoods.removeAt(index));
                              setState(() {}); // trigger update in parent pill
                              if (_sessionAddedFoods.isEmpty) Navigator.pop(context);
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
    final tp = Provider.of<TranslationProvider>(context);

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
                  transform: Matrix4.identity()..scale(_justAddedAnimation ? 1.05 : 1.0),
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
                  child: const Text(
                    'Just Added',
                    style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          widget.mealType ?? tp.translate('add_food'),
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
                controller: _searchController,
                style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'What did you have for ${widget.mealType?.toLowerCase() ?? 'meal'}?',
                  hintStyle: TextStyle(color: AppTheme.secondaryText.withValues(alpha: 0.8), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText, size: 24),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondaryText, size: 24),
                    onPressed: () async {
                      var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimpleBarcodeScannerPage(),
                        ),
                      );
                      if (res is String && res != '-1' && mounted) {
                        setState(() {
                          _searchController.text = res;
                        });
                        // At this point we would trigger a lookup in the OpenFoodFacts API, 
                        // but for now we just populate the search bar with the barcode.
                      }
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Categories row
          if (!_showManualMenu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryBox('Foods', Icons.restaurant, AppTheme.accentOrange),
                  const SizedBox(width: 16),
                  _buildCategoryBox('Meals', Icons.lunch_dining, AppTheme.accentGreen),
                  const SizedBox(width: 16),
                  _buildCategoryBox('Recipes', Icons.menu_book, AppTheme.accentYellow),
                ],
              ),
            ),
          
          if (!_showManualMenu) const SizedBox(height: 24),

          // Tabs
          if (!_showManualMenu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildTab('Frequent'),
                    _buildTab('Recent'),
                    _buildTab('Favorites'),
                  ],
                ),
              ),
            ),

          if (!_showManualMenu) const SizedBox(height: 16),

          // List or Manual form
          Expanded(
            child: _showManualMenu
                ? _buildManualMenu()
                : (_filteredPresets.isEmpty)
                    ? _buildEmptyState(tp)
                    : ListView.separated(
                        itemCount: _filteredPresets.length,
                        separatorBuilder: (context, index) => Divider(color: AppTheme.secondaryText.withValues(alpha: 0.1), height: 1),
                        itemBuilder: (context, index) {
                          final preset = _filteredPresets[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(preset.name, style: const TextStyle(color: AppTheme.primaryText, fontSize: 16, fontWeight: FontWeight.w500)),
                            subtitle: Text('1 regular serving', style: TextStyle(color: AppTheme.secondaryText.withValues(alpha: 0.8), fontSize: 12)),
                            onTap: () async {
                              final addedFood = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FoodDetailsPage(
                                    food: preset,
                                    mealType: widget.mealType,
                                  ),
                                ),
                              );
                              if (addedFood != null && addedFood is Food) {
                                setState(() {
                                  _sessionAddedFoods.add(addedFood);
                                });
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${(preset.kcalPer100g ?? preset.calories).toInt()} kcal', style: const TextStyle(color: AppTheme.primaryText, fontSize: 14)),
                                const SizedBox(width: 12),
                                Consumer<NutritionProvider>(
                                  builder: (context, provider, child) {
                                    final isFav = provider.favoritePresetIds.contains(preset.id);
                                    return GestureDetector(
                                      onTap: () {
                                        provider.toggleFavoritePreset(preset.id);
                                        if (_selectedTab == 'Favorites') {
                                           // Re-filter so to immediately remove from screen if untoggled in the filtered view
                                           _filterPresets();
                                        }
                                      },
                                      child: Icon(
                                        isFav ? Icons.star : Icons.star_border,
                                        color: isFav ? AppTheme.accentYellow : AppTheme.secondaryText.withValues(alpha: 0.5),
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _addFood(preset),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _animatingFoodIds.contains(preset.id) ? AppTheme.accentGreen : Colors.transparent,
                                      border: Border.all(color: AppTheme.accentGreen, width: 1.5),
                                    ),
                                    child: Icon(
                                      _animatingFoodIds.contains(preset.id) ? Icons.check : Icons.add, 
                                      color: _animatingFoodIds.contains(preset.id) ? AppTheme.backgroundColor : AppTheme.accentGreen, 
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom sticky "Done" button if not in manual menu
          if (!_showManualMenu)
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
    final tp = Provider.of<TranslationProvider>(context);
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
                      ? tp.translate('protein')
                      : _touchedIndex == 1
                      ? tp.translate('carbs')
                      : _touchedIndex == 2
                      ? tp.translate('fats')
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
                      onPressed: () {
                        Provider.of<NutritionProvider>(
                          context,
                          listen: false,
                        ).removeFood(food.id);
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

