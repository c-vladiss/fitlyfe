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
  String _selectedUnit = '100g';
  final List<String> _units = ['100g', 'Serving (150 g)'];

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

  void _addFood() {
    final qty = double.tryParse(_quantityController.text) ?? 1.0;
    
    double ratio = 1.0;
    if (_selectedUnit == 'Serving (150 g)') {
      ratio = qty * 1.5;
    } else {
      ratio = qty;
    }

    final scaledMicros = <String, double>{};
    widget.food.micronutrients.forEach((key, value) {
      scaledMicros[key] = value * ratio;
    });

    final newFood = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.food.name,
      calories: widget.food.calories * ratio,
      protein: widget.food.protein * ratio,
      carbs: widget.food.carbs * ratio,
      fats: widget.food.fats * ratio,
      micronutrients: scaledMicros,
      dateAdded: Provider.of<NutritionProvider>(context, listen: false).selectedDate,
      mealType: widget.mealType,
    );
    
    Provider.of<NutritionProvider>(context, listen: false).addFood(newFood);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NutritionProvider>(context);
    final isFavorite = provider.favoritePresetIds.contains(widget.food.id);

    final qty = double.tryParse(_quantityController.text) ?? 1.0;
    double ratio = _selectedUnit == 'Serving (150 g)' ? qty * 1.5 : qty;

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
            onPressed: () => provider.toggleFavoritePreset(widget.food.id),
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
                  child: Text(
                    widget.food.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
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

                // Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: AppTheme.accentBlue, size: 16),
                    const SizedBox(width: 8),
                    const Text('Verified nutrition facts', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: AppTheme.accentGreen.withValues(alpha: 0.8), size: 16),
                    const SizedBox(width: 8),
                    const Text('Recently logged', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 32),

                // Food Rating Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Food Rating', style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        'Our smart food rating tells you what is good and bad about this food.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen, 
                          foregroundColor: AppTheme.backgroundColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {},
                        child: const Text('Unlock All', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Nutrition Facts
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Nutrition Facts', style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 16),

                _buildNutritionRow('Calories', '${currentCalories.round()} kcal', isBold: true),
                _buildNutritionRow('Protein', '${currentProtein.toStringAsFixed(1)} g', isBold: true),
                _buildNutritionRow('Carbs', '${currentCarbs.toStringAsFixed(1)} g', isBold: true),
                _buildNutritionRow('Fibre', '---', showProBadge: true),
                _buildNutritionRow('of which Sugars', '---', showProBadge: true),
                
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
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.secondaryText),
                              dropdownColor: AppTheme.backgroundColor,
                              isExpanded: true,
                              style: const TextStyle(color: AppTheme.primaryText),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
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
                      onPressed: _addFood,
                      child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildNutritionRow(String label, String value, {bool isBold = false, bool showProBadge = false}) {
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
          if (showProBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Pro', style: TextStyle(color: AppTheme.backgroundColor, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
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
