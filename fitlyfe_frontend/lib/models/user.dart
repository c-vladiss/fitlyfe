class User {
  final String id;
  final String name;
  final String email;
  final String? imageUrl;
  final double weight; // in kg
  final double height; // in cm
  final int age;
  final String goal;
  final double dailyCalorieGoal;
  final int dailyStepGoal;
  final int dailyActiveTimeGoal; // in minutes
  final int streakCount;
  final DateTime? lastLoginDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
    required this.weight,
    required this.height,
    required this.age,
    this.goal = 'Stay Fit',
    this.dailyCalorieGoal = 2000,
    this.dailyStepGoal = 10000,
    this.dailyActiveTimeGoal = 60,
    this.streakCount = 0,
    this.lastLoginDate,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? imageUrl,
    double? weight,
    double? height,
    int? age,
    String? goal,
    double? dailyCalorieGoal,
    int? dailyStepGoal,
    int? dailyActiveTimeGoal,
    int? streakCount,
    DateTime? lastLoginDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      goal: goal ?? this.goal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyActiveTimeGoal: dailyActiveTimeGoal ?? this.dailyActiveTimeGoal,
      streakCount: streakCount ?? this.streakCount,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}
