import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/food_item_card.dart';
import 'package:fitlyfe_frontend/widgets/micronutrient_card.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitlyfe_frontend/screens/nutrition_details_page.dart';
import 'package:fitlyfe_frontend/screens/meal_settings_page.dart';
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
    showDialog(context: context, builder: (context) => AddFoodDialog(mealType: mealType));
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
                  suffixText:
                      selectedType.contains('vitamin_a') ||
                          selectedType.contains('vitamin_d')
                      ? 'mcg'
                      : 'mg',
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

class AddFoodDialog extends StatefulWidget {
  final String? mealType;
  const AddFoodDialog({super.key, this.mealType});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _weightController = TextEditingController(text: '100');
  final _searchController = TextEditingController();

  Food? _selectedPreset;
  List<Food> _filteredPresets = NutritionProvider.presets;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPresets);
  }

  void _filterPresets() {
    setState(() {
      _filteredPresets = NutritionProvider.presets
          .where(
            (p) => p.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  void _onPresetSelected(Food preset) {
    setState(() {
      _selectedPreset = preset;
      _nameController.text = preset.name;
      _updateFieldsFromWeight();
    });
  }

  void _updateFieldsFromWeight() {
    if (_selectedPreset == null) return;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final ratio = weight / 100.0;

    _caloriesController.text = (_selectedPreset!.kcalPer100g! * ratio)
        .toInt()
        .toString();
    _proteinController.text = (_selectedPreset!.protein * ratio)
        .toStringAsFixed(1);
    _carbsController.text = (_selectedPreset!.carbs * ratio).toStringAsFixed(1);
    _fatsController.text = (_selectedPreset!.fats * ratio).toStringAsFixed(1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? AppTheme.secondaryText : AppTheme.primaryText),
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.backgroundColor.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryText.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryText.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: readOnly ? AppTheme.secondaryText.withValues(alpha: 0.3) : AppTheme.accentGreen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TranslationProvider>(context);

    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        tp.translate('add_food'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tp.translate('presets'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  if (_selectedPreset != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedPreset = null),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: tp.translate('search_foods'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredPresets.length,
                  itemBuilder: (context, index) {
                    final preset = _filteredPresets[index];
                    final isSelected = _selectedPreset?.id == preset.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(preset.name),
                        onPressed: () => _onPresetSelected(preset),
                        backgroundColor: isSelected
                            ? AppTheme.accentGreen
                            : AppTheme.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.backgroundColor
                              : AppTheme.primaryText,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.accentGreen
                                : AppTheme.secondaryText.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Divider(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
              const SizedBox(height: 16),

              if (_selectedPreset != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        labelText: tp.translate('weight_g'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateFieldsFromWeight(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPreset!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedPreset!.kcalPer100g} ${tp.translate('kcal')} ${tp.translate('per_100g')}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _nameController,
                labelText: tp.translate('food_name'),
                hintText: tp.translate('food_name_hint'),
                readOnly: _selectedPreset != null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _caloriesController,
                labelText: tp.translate('calories'),
                hintText: '350',
                keyboardType: TextInputType.number,
                readOnly: _selectedPreset != null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _proteinController,
                      labelText: tp.translate('protein_g'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: _selectedPreset != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _carbsController,
                      labelText: tp.translate('carbs_g'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: _selectedPreset != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _fatsController,
                      labelText: tp.translate('fats_g'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: _selectedPreset != null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            if (_nameController.text.isEmpty) return;

            final weight = double.tryParse(_weightController.text) ?? 100;
            final ratio = weight / 100.0;
            final scaledMicros = <String, double>{};

            if (_selectedPreset != null) {
              _selectedPreset!.micronutrients.forEach((key, value) {
                scaledMicros[key] = value * ratio;
              });
            }

            final food = Food(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              calories: double.tryParse(_caloriesController.text) ?? 0,
              protein: double.tryParse(_proteinController.text) ?? 0,
              carbs: double.tryParse(_carbsController.text) ?? 0,
              fats: double.tryParse(_fatsController.text) ?? 0,
              micronutrients: scaledMicros,
              dateAdded: Provider.of<NutritionProvider>(context, listen: false).selectedDate,
              mealType: widget.mealType,
            );
            Provider.of<NutritionProvider>(
              context,
              listen: false,
            ).addFood(food);
            Navigator.pop(context);
          },
          child: Text(tp.translate('add')),
        ),
      ],
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
                  // Protein Section (Index 0)
                  if (proteinCals > 0)
                    PieChartSectionData(
                      value: proteinCals,
                      color: AppTheme.accentBlue,
                      radius: _touchedIndex == 0 ? 16 : 10,
                      showTitle: false,
                    ),
                  // Carbs Section (Index 1)
                  if (carbsCals > 0)
                    PieChartSectionData(
                      value: carbsCals,
                      color: AppTheme.accentGreen,
                      radius: _touchedIndex == 1 ? 16 : 10,
                      showTitle: false,
                    ),
                  // Fats Section (Index 2)
                  if (fatsCals > 0)
                    PieChartSectionData(
                      value: fatsCals,
                      color: AppTheme.accentOrange,
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

  Widget _buildMacroBadge(
    IconData icon,
    Color color, {
    required bool isHovered,
    required String value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: isHovered ? 8 : 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (isHovered) ...[
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
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
                    child: Text(emojiStr, style: const TextStyle(fontSize: 24)),
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
                          '${totalCals.toInt()} / ${goalCals} Cal',
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

