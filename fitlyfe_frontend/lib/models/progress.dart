class ProgressData {
  final DateTime date;
  final double caloriesBurned;
  final double? weight;
  final Duration? workoutTime;
  final int? steps;

  ProgressData({
    required this.date,
    required this.caloriesBurned,
    this.weight,
    this.workoutTime,
    this.steps,
  });

  ProgressData copyWith({
    DateTime? date,
    double? caloriesBurned,
    double? weight,
    Duration? workoutTime,
    int? steps,
  }) {
    return ProgressData(
      date: date ?? this.date,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      weight: weight ?? this.weight,
      workoutTime: workoutTime ?? this.workoutTime,
      steps: steps ?? this.steps,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String description;
  final String category;
  final double targetValue;
  final double currentValue;
  final DateTime targetDate;
  final bool isCompleted;
  final bool isBoolean;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.targetDate,
    this.isCompleted = false,
    this.isBoolean = false,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? targetValue,
    double? currentValue,
    DateTime? targetDate,
    bool? isCompleted,
    bool? isBoolean,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isBoolean: isBoolean ?? this.isBoolean,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final DateTime? unlockedDate;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    this.unlockedDate,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? icon,
    DateTime? unlockedDate,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

class Tip {
  final String id;
  final String title;
  final String content;
  final String category;

  Tip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });
}
