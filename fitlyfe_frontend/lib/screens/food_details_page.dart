import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/models/food.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class FoodDetailsPage extends StatefulWidget {
  final Food food;
  final String? mealType;

  const FoodDetailsPage({super.key, required this.food, this.mealType});

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  late TextEditingController _quantityController;
  // Portions the quantity can be counted in, as (label, grams per unit)
  late final List<(String, double)> _units = [
    ('100 g', 100),
    if (widget.food.servingSizeG != null && widget.food.servingSizeG! > 0)
      ('Serving (${_formatGrams(widget.food.servingSizeG!)} g)', widget.food.servingSizeG!),
    ('Gram', 1),
  ];
  late (String, double) _selectedUnit = _units.length > 2 ? _units[1] : _units[0];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _quantityController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  /// Grams described by the quantity field and unit, or null if invalid.
  double? get _grams {
    final qty = double.tryParse(_quantityController.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) return null;
    return qty * _selectedUnit.$2;
  }

  static String _formatGrams(double grams) =>
      grams == grams.roundToDouble() ? grams.toInt().toString() : grams.toStringAsFixed(1);

  Future<void> _addFood() async {
    final grams = _grams;
    final messenger = ScaffoldMessenger.of(context);
    if (grams == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<NutritionProvider>(context, listen: false);
    final entryId = await provider.addFoodToMeal(
      foodEntryId: widget.food.id,
      mealType: widget.mealType ?? 'Snacks',
      quantityG: grams,
      food: widget.food,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    messenger.clearSnackBars();
    if (entryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add the food. Please try again.')),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Food added successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      )
    );
    // The logged entry, so the caller can list (and undo) it
    final ratio = grams / 100;
    Navigator.pop(
      context,
      widget.food.copyWith(
        id: entryId,
        calories: widget.food.calories * ratio,
        protein: widget.food.protein * ratio,
        carbs: widget.food.carbs * ratio,
        fats: widget.food.fats * ratio,
        servingSizeG: grams,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NutritionProvider>(context);
    final isFavorite = provider.isFavorite(widget.food.id);

    // Nutrition values are per 100 g
    final ratio = (_grams ?? 0) / 100;

    final currentCalories = widget.food.calories * ratio;
    final currentCarbs = widget.food.carbs * ratio;
    final currentProtein = widget.food.protein * ratio;
    final currentFats = widget.food.fats * ratio;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.accentGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mealType ?? 'Food Details',
          style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppTheme.accentYellow : AppTheme.accentGreen,
            ),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () => provider.toggleFavorite(widget.food),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.cardBackground, AppTheme.backgroundColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.food.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                      ),
                      if (widget.food.brand != null && widget.food.brand!.isNotEmpty)
                        Text(widget.food.brand!, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Macros Overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMacroItem('${currentCalories.round()} kcal', 'Calories'),
                      _buildMacroItem('${currentCarbs.toStringAsFixed(1)} g', 'Carbs'),
                      _buildMacroItem('${currentProtein.toStringAsFixed(1)} g', 'Protein'),
                      _buildMacroItem('${currentFats.toStringAsFixed(1)} g', 'Fat'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nutrition Facts
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Nutrition Facts', style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 16),

                _buildNutritionRow('Calories', '${currentCalories.round()} kcal', isBold: true),
                _buildNutritionRow('Protein', '${currentProtein.toStringAsFixed(1)} g', isBold: true),
                _buildNutritionRow('Carbs', '${currentCarbs.toStringAsFixed(1)} g', isBold: true),
                _buildNutritionRow('Fat', '${currentFats.toStringAsFixed(1)} g', isBold: true),
                
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
              decoration: const BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Quantity input
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            key: const Key('quantityField'),
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      // Unit dropdown
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                            border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<(String, double)>(
                              value: _selectedUnit,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.secondaryText),
                              dropdownColor: AppTheme.backgroundColor,
                              isExpanded: true,
                              style: const TextStyle(color: AppTheme.primaryText),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.$1),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _isSaving ? null : _addFood,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundColor),
                            )
                          : const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.primaryText : AppTheme.secondaryText,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }
}
