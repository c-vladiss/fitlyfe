import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/utils/meal_icon_mapping.dart';
import 'package:fitlyfe_frontend/screens/nutrition_page.dart';

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

class StripedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 4;
    for (double i = -size.height; i < size.width; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MealSettingsPageState extends State<MealSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late String _currentIconKey;
  bool _isNew = false;

  final List<String> _iconPickerList = [
    'coffee', 'soup_kitchen', 'dinner', 'cookie', 'lunch_dining', 
    'pizza', 'cake', 'meat', 'egg', 'drink', 'restaurant', 'flatware'
  ];

  @override
  void initState() {
    super.initState();
    _isNew = widget.currentMeal == null;
    _nameController = TextEditingController(text: widget.currentMeal?.name ?? '');
    _goalController = TextEditingController(text: widget.currentMeal != null ? widget.currentMeal!.goalCals.toString() : '');
    _currentIconKey = widget.currentMeal?.emoji ?? 'flatware';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final goal = int.tryParse(_goalController.text.trim()) ?? 500;
    final provider = Provider.of<NutritionProvider>(context, listen: false);

    if (_isNew) {
      provider.addMealGlobally(MealInfo(name, _currentIconKey, goal));
      Navigator.pop(context);
    } else {
      provider.updateMealGlobally(widget.currentMeal!.name, MealInfo(name, _currentIconKey, goal));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddFoodSearchSheet(mealType: name),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Icon', style: TextStyle(color: AppTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _iconPickerList.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  final newIcon = _iconPickerList[index];
                  setState(() => _currentIconKey = newIcon);
                  
                  if (!_isNew && widget.currentMeal != null) {
                    final provider = Provider.of<NutritionProvider>(context, listen: false);
                    provider.updateMealGlobally(
                      widget.currentMeal!.name, 
                      MealInfo(widget.currentMeal!.name, newIcon, widget.currentMeal!.goalCals)
                    );
                  }
                  
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: MealIconMapping.buildIcon(_iconPickerList[index], size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    
    final foods = nutritionProvider.todayFoods.where((f) => f.mealType == _nameController.text).toList();
    
    final mealCalories = foods.fold(0.0, (s, f) => s + f.calories);
    final mealCarbs = foods.fold(0.0, (s, f) => s + f.carbs);
    final mealProtein = foods.fold(0.0, (s, f) => s + f.protein);
    final mealFat = foods.fold(0.0, (s, f) => s + f.fats);

    final goalCals = int.tryParse(_goalController.text) ?? 500;
    final carbsGoal = (goalCals * 0.40) / 4;
    final proteinGoal = (goalCals * 0.30) / 4;
    final fatGoal = (goalCals * 0.30) / 9;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isNew 
          ? Container(
              height: 38,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppTheme.accentGreen, width: 1.5),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Add Name',
                  hintStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
                onChanged: (v) => setState(() {}),
              ),
            )
          : Text(
              _nameController.text,
              style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
            ),
        centerTitle: true,
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: const Text('Delete Meal', style: TextStyle(color: AppTheme.primaryText)),
                    content: Text('Are you sure you want to delete "${_nameController.text}"?', style: const TextStyle(color: AppTheme.secondaryText)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<NutritionProvider>(context, listen: false)
                              .deleteMealGlobally(widget.currentMeal!.name);
                          Navigator.pop(context); // Pop dialog
                          Navigator.pop(context); // Pop page
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Green Banner
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF034732), // Dark forest green
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MealIconMapping.buildIcon(_currentIconKey, size: 72, overrideColor: Colors.white),
                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppTheme.accentGreen,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2x2 Grid Macros Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  _isNew
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IntrinsicWidth(
                                            child: TextField(
                                              controller: _goalController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                                border: InputBorder.none,
                                                hintText: 'Add Calories',
                                                hintStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 13, fontWeight: FontWeight.normal),
                                              ),
                                              onChanged: (v) => setState(() {}),
                                            ),
                                          ),
                                          const Text(' kcal', style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      )
                                    : Text('${mealCalories.round()} kcal', style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Calories', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 60, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text('${mealCarbs.toStringAsFixed(1)} g', style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Carbs', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 1, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text('${mealProtein.toStringAsFixed(1)} g', style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Protein', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 60, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text('${mealFat.toStringAsFixed(1)} g', style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Fat', style: TextStyle(color: AppTheme.secondaryText, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Nutrition Facts Label
                const Text(
                  'Nutrition Facts',
                  style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Striped Locked Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Content layer (semi-transparent due to lock overlay)
                      Opacity(
                        opacity: 0.4,
                        child: Column(
                          children: [
                            _buildLockedRow('Calories', '${mealCalories.round()} / $goalCals kcal'),
                            Divider(height: 1, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                            _buildLockedRow('Carbs', '${mealCarbs.toStringAsFixed(1)} / ${carbsGoal.round()} g'),
                            Divider(height: 1, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                            _buildLockedRow('Protein', '${mealProtein.toStringAsFixed(1)} / ${proteinGoal.round()} g'),
                            Divider(height: 1, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                            _buildLockedRow('Fat', '${mealFat.toStringAsFixed(1)} / ${fatGoal.round()} g'),
                          ],
                        ),
                      ),
                      // Stripes layer
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: StripedPainter(),
                          ),
                        ),
                      ),
                      // Pro Button overlay
                      IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, color: Colors.black, size: 14),
                              SizedBox(width: 6),
                              Text('Pro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Basic Visible Stats
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildBasicRow('Calories', '${mealCalories.round()} kcal', isBold: true),
                      Divider(height: 1, color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                      _buildBasicRow('Protein', '${mealProtein.toStringAsFixed(1)} g', isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Fixed Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryText, // White button
                  foregroundColor: AppTheme.backgroundColor, // Dark text
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _saveMeal,
                child: Text(_isNew ? 'Save Meal' : 'Track now', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedRow(String label, String value, {Widget? suffixWidget, String? suffixLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.primaryText, fontSize: 15)),
          Row(
            children: [
              Text(value, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 15)),
              ?suffixWidget,
              if (suffixLabel != null) Text(suffixLabel, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: AppTheme.primaryText, 
              fontSize: 16, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal
            )
          ),
          Text(
            value, 
            style: TextStyle(
              color: AppTheme.primaryText, 
              fontSize: 16, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      ),
    );
  }
}

