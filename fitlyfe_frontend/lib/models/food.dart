class Food {
  final String id;
  final String name;
  final double calories;
  final double protein; // in grams
  final double carbs; // in grams
  final double fats; // in grams
  final double? kcalPer100g; // Optional for presets
  final Map<String, double> micronutrients; // e.g., {'vitamin_a': 0.02, 'vitamin_c': 0.15}
  final DateTime dateAdded;
  final String? imageUrl;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.kcalPer100g,
    this.micronutrients = const {},
    required this.dateAdded,
    this.imageUrl,
  });

  Food copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    double? kcalPer100g,
    Map<String, double>? micronutrients,
    DateTime? dateAdded,
    String? imageUrl,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      micronutrients: micronutrients ?? this.micronutrients,
      dateAdded: dateAdded ?? this.dateAdded,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
