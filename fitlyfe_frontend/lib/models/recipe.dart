import 'package:fitlyfe_frontend/models/food.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final List<String> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final String category; // e.g., 'Breakfast', 'Lunch', 'High Protein'

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    required this.category,
  });

  Food toFood() {
    return Food(
      id: 'recipe_$id',
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      dateAdded: DateTime.now(),
    );
  }
}

final List<Recipe> premadeRecipes = [
  Recipe(
    id: '1',
    name: 'Grilled Salmon & Quinoa',
    description: 'A nutrient-dense meal rich in Omega-3s and complex carbs.',
    calories: 450,
    protein: 35,
    carbs: 30,
    fats: 18,
    category: 'Lunch',
    ingredients: [
      '150g Salmon fillet',
      '1/2 cup Cooked quinoa',
      '1 cup Steamed broccoli',
      '1 tbsp Olive oil',
      'Lemon & Herbs'
    ],
    instructions: [
      'Season salmon with herbs and lemon.',
      'Grill for 4-5 minutes per side.',
      'Serve over quinoa with a side of broccoli.'
    ],
    imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop',
  ),
  Recipe(
    id: '2',
    name: 'Berry Protein Bowl',
    description: 'Perfect low-calorie, high-protein breakfast to start your day.',
    calories: 280,
    protein: 24,
    carbs: 22,
    fats: 6,
    category: 'Breakfast',
    ingredients: [
      '200g Greek Yogurt (0%)',
      '1/2 cup Mixed berries',
      '1/2 scoop Protein powder',
      '1 tsp Chia seeds'
    ],
    instructions: [
      'Mix yogurt and protein powder until smooth.',
      'Top with berries and chia seeds.'
    ],
    imageUrl: 'https://images.unsplash.com/photo-1481931098730-318b6f776db0?q=80&w=400&auto=format&fit=crop',
  ),
  Recipe(
    id: '3',
    name: 'Lean Chicken Salad',
    description: 'Classic high-protein lunch with minimal fats and carbs.',
    calories: 320,
    protein: 42,
    carbs: 8,
    fats: 12,
    category: 'Lunch',
    ingredients: [
      '180g Chicken breast',
      '2 cups Mixed greens',
      '1/4 Avocado',
      'Lemon vinaigrette'
    ],
    instructions: [
      'Grill chicken breast and slice into strips.',
      'Toss greens with vinaigrette.',
      'Top with chicken and avocado slices.'
    ],
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
  ),
  Recipe(
    id: '4',
    name: 'Avocado Egg Toast',
    description: 'Healthy fats and protein on whole-grain sourdough.',
    calories: 380,
    protein: 16,
    carbs: 28,
    fats: 24,
    category: 'Breakfast',
    ingredients: [
      '1 slice Sourdough bread',
      '1/2 Avocado',
      '1 Poached egg',
      'Red pepper flakes'
    ],
    instructions: [
      'Toast the bread.',
      'Mash avocado with a pinch of salt.',
      'Top with poached egg and red pepper flakes.'
    ],
    imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400&auto=format&fit=crop',
  ),
];
