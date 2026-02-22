import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/food_item_card.dart';
import 'package:fitlyfe_frontend/widgets/micronutrient_card.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/models/recipe.dart';
import 'package:fl_chart/fl_chart.dart';

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

              // Calorie & Macro Progress
              _CalorieMacroChart(
                caloriesGoal: caloriesGoal,
                caloriesConsumed: caloriesConsumed,
                protein: nutritionProvider.todayProtein,
                carbs: nutritionProvider.todayCarbs,
                fats: nutritionProvider.todayFats,
              ),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${caloriesConsumed.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${user.dailyCalorieGoal.toInt()} KCAL',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Macronutrients
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      tp.translate('macronutrients'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _buildMacroRow(
                      context,
                      tp.translate('protein'),
                      nutritionProvider.todayProtein,
                      proteinGoal,
                      AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildMacroRow(
                      context,
                      tp.translate('carbs'),
                      nutritionProvider.todayCarbs,
                      carbsGoal,
                      AppTheme.accentGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildMacroRow(
                      context,
                      tp.translate('fats'),
                      nutritionProvider.todayFats,
                      fatsGoal,
                      AppTheme.accentOrange,
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

              // Healthy Recipes Section
              _buildRecipesSection(context, tp),
              const SizedBox(height: 32),

              // Today's Log
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tp.translate('today_log'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFoodDialog(context, tp),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(tp.translate('add_food')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.backgroundColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...nutritionProvider.todayFoods.map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FoodItemCard(food: food),
                ),
              ),
              if (nutritionProvider.todayFoods.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      tp.translate('no_food_logged'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    double value,
    double goal,
    Color color,
  ) {
    final progress = (value / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${value.toInt()}g',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${goal.toInt()}g',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.backgroundColor, // Background track color
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipesSection(BuildContext context, TranslationProvider tp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tp.translate('healthy_recipes'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              tp.translate('low_cal_options'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.accentGreen),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: premadeRecipes.length,
            itemBuilder: (context, index) {
              final recipe = premadeRecipes[index];
              return _buildRecipeCard(context, recipe, tp);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    TranslationProvider tp,
  ) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(context, recipe, tp),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(recipe.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${recipe.calories.toInt()} kcal',
                  style: const TextStyle(
                    color: AppTheme.backgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.egg_outlined,
                    size: 12,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.protein.toInt()}g',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.opacity,
                    size: 12,
                    color: AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.fats.toInt()}g',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipeDetails(
    BuildContext context,
    Recipe recipe,
    TranslationProvider tp,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(recipe.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.name,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.category,
                                style: TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${recipe.calories.toInt()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              const Text(
                                'KCAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Macro Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _recipeMacroStat(
                          'Protein',
                          '${recipe.protein.toInt()}g',
                          AppTheme.accentBlue,
                        ),
                        _recipeMacroStat(
                          'Carbs',
                          '${recipe.carbs.toInt()}g',
                          AppTheme.accentGreen,
                        ),
                        _recipeMacroStat(
                          'Fats',
                          '${recipe.fats.toInt()}g',
                          AppTheme.accentOrange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppTheme.accentGreen,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              ing,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...recipe.instructions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}.',
                              style: const TextStyle(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<NutritionProvider>(
                            context,
                            listen: false,
                          ).addFood(recipe.toFood());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${recipe.name} to your log!',
                              ),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Daily Log'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, TranslationProvider tp) {
    showDialog(context: context, builder: (context) => const AddFoodDialog());
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
  const AddFoodDialog({super.key});

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
                      child: TextField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: tp.translate('weight_g'),
                        ),
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

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tp.translate('food_name'),
                  hintText: tp.translate('food_name_hint'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: tp.translate('calories'),
                  hintText: '350',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      decoration: InputDecoration(
                        labelText: tp.translate('protein_g'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      decoration: InputDecoration(
                        labelText: tp.translate('carbs_g'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _fatsController,
                      decoration: InputDecoration(
                        labelText: tp.translate('fats_g'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
              dateAdded: DateTime.now(),
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

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
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
                centerSpaceRadius: 85,
                startDegreeOffset: -90,
                sections: [
                  // Protein Section (Index 0)
                  if (proteinCals > 0)
                    PieChartSectionData(
                      value: proteinCals,
                      color: AppTheme.accentBlue,
                      radius: _touchedIndex == 0 ? 30 : 22,
                      showTitle: false,
                      badgeWidget: _buildMacroBadge(
                        Icons.egg,
                        AppTheme.accentBlue,
                        isHovered: _touchedIndex == 0,
                        value: '${widget.protein.toInt()}g',
                      ),
                      badgePositionPercentageOffset: 0.98,
                    ),
                  // Carbs Section (Index 1)
                  if (carbsCals > 0)
                    PieChartSectionData(
                      value: carbsCals,
                      color: AppTheme.accentGreen,
                      radius: _touchedIndex == 1 ? 30 : 22,
                      showTitle: false,
                      badgeWidget: _buildMacroBadge(
                        Icons.bakery_dining,
                        AppTheme.accentGreen,
                        isHovered: _touchedIndex == 1,
                        value: '${widget.carbs.toInt()}g',
                      ),
                      badgePositionPercentageOffset: 0.98,
                    ),
                  // Fats Section (Index 2)
                  if (fatsCals > 0)
                    PieChartSectionData(
                      value: fatsCals,
                      color: AppTheme.accentOrange,
                      radius: _touchedIndex == 2 ? 30 : 22,
                      showTitle: false,
                      badgeWidget: _buildMacroBadge(
                        Icons.opacity,
                        AppTheme.accentOrange,
                        isHovered: _touchedIndex == 2,
                        value: '${widget.fats.toInt()}g',
                      ),
                      badgePositionPercentageOffset: 0.98,
                    ),
                  // Remaining Calories Section (Index 3 if all macros exist, otherwise varies)
                  // To keep it simple, we check remaining last
                  if (caloriesRemaining > 0)
                    PieChartSectionData(
                      value: caloriesRemaining,
                      color: AppTheme.cardBackground,
                      radius: 15,
                      showTitle: false,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _touchedIndex == 0
                      ? '${proteinCals.toInt()}'
                      : _touchedIndex == 1
                      ? '${carbsCals.toInt()}'
                      : _touchedIndex == 2
                      ? '${fatsCals.toInt()}'
                      : caloriesRemaining.toInt().toString(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                  ),
                ),
                Text(
                  _touchedIndex == 0
                      ? '${tp.translate('protein').toUpperCase()} KCAL'
                      : _touchedIndex == 1
                      ? '${tp.translate('carbs').toUpperCase()} KCAL'
                      : _touchedIndex == 2
                      ? '${tp.translate('fats').toUpperCase()} KCAL'
                      : tp.translate('kcal_left'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
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
