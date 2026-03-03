import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/food_item_card.dart';

class MealSettingsPage extends StatefulWidget {
  final DateTime date;
  final MealInfo? currentMeal;

  const MealSettingsPage({
    super.key,
    required this.date,
    this.currentMeal,
  });

  @override
  State<MealSettingsPage> createState() => _MealSettingsPageState();
}

class _MealSettingsPageState extends State<MealSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentMeal?.name ?? '');
    _emojiController = TextEditingController(text: widget.currentMeal?.emoji ?? '🍽️');
    _goalController = TextEditingController(
        text: widget.currentMeal?.goalCals.toString() ?? '500');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    if (_nameController.text.trim().isEmpty) return;

    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim().isEmpty ? '🍽️' : _emojiController.text.trim();
    final goal = int.tryParse(_goalController.text.trim()) ?? 500;

    final provider = Provider.of<NutritionProvider>(context, listen: false);

    if (widget.currentMeal != null) {
      provider.updateMealForDate(widget.date, widget.currentMeal!.name, MealInfo(name, emoji, goal));
    } else {
      provider.addMealForDate(widget.date, MealInfo(name, emoji, goal));
    }

    Navigator.pop(context);
  }

  void _deleteMeal() {
    if (widget.currentMeal != null) {
      Provider.of<NutritionProvider>(context, listen: false)
          .deleteMealForDate(widget.date, widget.currentMeal!.name);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TranslationProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final isNew = widget.currentMeal == null;

    final foods = isNew 
        ? [] 
        : nutritionProvider.todayFoods.where((f) => f.mealType == widget.currentMeal!.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add Custom Meal' : 'Edit Meal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryText),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _emojiController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: '🍽️',
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IntrinsicWidth(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold, 
                              color: AppTheme.primaryText,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'Meal Name',
                              hintStyle: TextStyle(
                                color: AppTheme.secondaryText.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${foods.fold(0.0, (sum, food) => sum + food.calories).toInt()} / ',
                              style: const TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                            ),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _goalController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  filled: true,
                                  fillColor: AppTheme.backgroundColor.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: '500',
                                  hintStyle: TextStyle(
                                    color: AppTheme.secondaryText.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Cal',
                              style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Meal', style: TextStyle(color: AppTheme.backgroundColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (!isNew) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _deleteMeal,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Delete Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (foods.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Added Foods',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...foods.map((food) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FoodItemCard(food: food),
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
