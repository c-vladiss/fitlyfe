import 'package:flutter/foundation.dart';
import 'package:fitlyfe_frontend/models/progress.dart';
import 'dart:async';

class ProgressProvider extends ChangeNotifier {
  final List<ProgressData> _progressData = [];
  final List<Goal> _goals = [];
  final List<Achievement> _achievements = [];

  final _completionController = StreamController<String>.broadcast();
  Stream<String> get completionStream => _completionController.stream;

  @override
  void dispose() {
    _completionController.close();
    super.dispose();
  }
  final List<Tip> _tips = [];

  List<ProgressData> get progressData => _progressData;
  List<Goal> get goals => _goals;
  List<Achievement> get achievements => _achievements;
  List<Tip> get tips => _tips;

  double get totalWorkoutHours {
    return _progressData.fold(0.0, (sum, data) {
      return sum + ((data.workoutTime?.inMinutes ?? 0.0) / 60.0);
    });
  }

  int get totalSteps {
    return _progressData.fold(0, (sum, data) {
      return sum + (data.steps ?? 0);
    });
  }

  double get totalWeightLost {
    if (_progressData.isEmpty) return 0.0;
    final sorted = List<ProgressData>.from(_progressData)..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first.weight ?? 0.0;
    final last = sorted.last.weight ?? first;
    return (first - last).clamp(0.0, double.infinity);
  }

  List<ProgressData> get last7DaysData {
    final now = DateTime.now();
    return _progressData.where((data) {
      final difference = now.difference(data.date).inDays;
      return difference <= 7;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  ProgressProvider() {
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    final now = DateTime.now();
    // Progress data
    for (int i = 6; i >= 0; i--) {
      _progressData.add(ProgressData(
        date: now.subtract(Duration(days: i)),
        caloriesBurned: 300 + (double.parse(i.toString()) * 50) + (double.parse((i % 3).toString()) * 100),
        weight: 75.0 - (double.parse(i.toString()) * 0.4),
        workoutTime: Duration(minutes: 45 + (i * 5)),
        steps: 4000 + (i * 1200) + (i % 2) * 500,
      ));
    }

    // Daily Goals
    _goals.addAll([
      _createGoal('d1', 'Daily', 'Walk 8,000 steps', 'Stay active every day', 8000, 4500),
      _createGoal('d2', 'Daily', 'Drink 2L of water', 'Stay hydrated', 2000, 1200),
      _createGoal('d3', 'Daily', 'Log all meals today', 'Track your nutrition', 1, 0, isBoolean: true),
    ]);

    // Workout Goals
    _goals.addAll([
      _createGoal('w1', 'Workout', 'Complete 3 workouts this week', 'Consistency is key', 3, 1),
      _createGoal('w2', 'Workout', 'Try a new workout type', 'Broaden your horizons', 1, 0, isBoolean: true),
      _createGoal('w3', 'Workout', 'Lift weights twice this week', 'Strength training', 2, 1),
      _createGoal('w4', 'Workout', 'Run 5 km total this week', 'Cardio endurance', 5, 2.5),
      _createGoal('w5', 'Workout', 'Do 100 pushups this week', 'Upper body strength', 100, 45),
      _createGoal('w6', 'Workout', 'Finish a HIIT session', 'High intensity training', 1, 0, isBoolean: true),
      _createGoal('w7', 'Workout', 'Train for 30 days straight', 'Build a solid habit', 30, 12),
      _createGoal('w8', 'Workout', 'Improve plank time by 30 seconds', 'Core stability', 30, 0),
      _createGoal('w9', 'Workout', 'Add 5 kg to a lift', 'Progressive overload', 5, 0),
      _createGoal('w10', 'Workout', 'Beat last workout duration', 'Push your limits', 1, 0, isBoolean: true),
    ]);

    // Health Goals
    _goals.addAll([
      _createGoal('h1', 'Health', 'Maintain heart rate in fat-burn zone for 15 min', 'Target fat loss', 15, 0),
      _createGoal('h2', 'Health', 'Reduce resting heart rate', 'Better cardiac health', 1, 0, isBoolean: true),
      _createGoal('h3', 'Health', 'Improve VO₂ max', 'Cardiorespiratory fitness', 1, 0, isBoolean: true),
      _createGoal('h4', 'Health', 'Lose 2 kg in a month', 'Weight management', 2, 0.5),
      _createGoal('h5', 'Health', 'Gain lean muscle', 'Body recomposition', 1, 0, isBoolean: true),
      _createGoal('h6', 'Health', 'Maintain calorie balance for 7 days', 'Nutritional consistency', 7, 3),
      _createGoal('h7', 'Health', 'Lower body fat percentage', 'Improve body composition', 1, 0, isBoolean: true),
      _createGoal('h8', 'Health', 'Meditate 5 days in a week', 'Mental well-being', 5, 2),
      _createGoal('h9', 'Health', 'Improve posture score', 'Physical alignment', 1, 0, isBoolean: true),
      _createGoal('h10', 'Health', 'Reduce stress levels', 'Overall wellness', 1, 0, isBoolean: true),
    ]);

    // Habit Goals
    _goals.addAll([
      _createGoal('hb1', 'Habit', 'Log activity for 14 days in a row', 'Consistency', 14, 5),
      _createGoal('hb2', 'Habit', 'Stretch every morning for a week', 'Flexibility', 7, 2),
      _createGoal('hb3', 'Habit', 'Drink water upon waking', 'Hydration habit', 7, 3),
      _createGoal('hb4', 'Habit', 'Walk daily for 30 days', 'Activity habit', 30, 10),
      _createGoal('hb5', 'Habit', 'Journal after workouts', 'Reflective practice', 1, 0, isBoolean: true),
      _createGoal('hb6', 'Habit', 'Track calories consistently', 'Data-driven nutrition', 7, 4),
      _createGoal('hb7', 'Habit', 'Sleep on schedule 5 days/week', 'Rest and recovery', 5, 2),
    ]);

    // Challenge Goals
    _goals.addAll([
      _createGoal('c1', 'Challenge', 'Complete a 7-day cardio challenge', 'Intensity push', 7, 0),
      _createGoal('c2', 'Challenge', '10k steps for 10 days', 'Consistency challenge', 10, 0),
      _createGoal('c3', 'Challenge', '100 km in a month', 'Distance challenge', 100, 0),
      _createGoal('c4', 'Challenge', '30 workouts in 30 days', 'Commitment challenge', 30, 0),
      _createGoal('c5', 'Challenge', 'No junk food week', 'Clean eating', 7, 0),
      _createGoal('c6', 'Challenge', 'Morning workouts only for 5 days', 'Discipline', 5, 0),
      _createGoal('c7', 'Challenge', 'Weekend warrior challenge', 'Active weekends', 1, 0, isBoolean: true),
      _createGoal('c8', 'Challenge', 'Hydration marathon', 'Maximum hydration', 1, 0, isBoolean: true),
    ]);

    // Beginner Milestones
    _achievements.addAll([
      _createAchievement('b1', 'Beginner', 'First Step', 'Logged first activity', '🚶'),
      _createAchievement('b2', 'Beginner', 'Getting Started', 'Completed first workout', '💪'),
      _createAchievement('b3', 'Beginner', 'Hydrated', 'Hit water goal once', '💧'),
      _createAchievement('b4', 'Beginner', 'Early Bird', 'Morning workout', '☀️'),
      _createAchievement('b5', 'Beginner', 'Night Owl', 'Evening workout', '🌙'),
      _createAchievement('b6', 'Beginner', 'Logged In', '3-day tracking streak', '📅'),
      _createAchievement('b7', 'Beginner', 'Stretch It Out', 'First stretch session', '🧘'),
      _createAchievement('b8', 'Beginner', 'Calorie Counter', 'First meal logged', '🍎'),
      _createAchievement('b9', 'Beginner', 'Mindful Moment', 'First meditation', '🧠'),
      _createAchievement('b10', 'Beginner', 'Sleep Champ', 'First full sleep log', '😴'),
    ]);

    // Streak Achievements
    _achievements.addAll([
      _createAchievement('s1', 'Streak', 'Consistency King/Queen', '7-day streak', '👑'),
      _createAchievement('s2', 'Streak', 'Unstoppable', '30-day streak', '🔥'),
      _createAchievement('s3', 'Streak', 'Legendary', '90-day streak', '🏆'),
      _createAchievement('s4', 'Streak', 'Habit Master', '14 straight days logged', '✅'),
      _createAchievement('s5', 'Streak', 'Waterfall', '10 hydration goals met', '🌊'),
      _createAchievement('s6', 'Streak', 'No Days Off', 'Worked out 10 days straight', '💥'),
      _createAchievement('s7', 'Streak', 'Daily Grinder', '50 active days', '⚙️'),
      _createAchievement('s8', 'Streak', 'Routine Builder', '5 weeks consistent', '🏗️'),
      _createAchievement('s9', 'Streak', 'Locked In', '100 check-ins', '🔒'),
      _createAchievement('s10', 'Streak', 'Never Missed Monday', '4 Mondays in a row', '📅'),
    ]);

    // Performance Achievements
    _achievements.addAll([
      _createAchievement('p1', 'Performance', 'PR Breaker', 'New personal record', '⚡'),
      _createAchievement('p2', 'Performance', '5K Finisher', 'Completed a 5 km run', '🏃'),
      _createAchievement('p3', 'Performance', 'Strength Starter', 'First weight session', '🏋️'),
      _createAchievement('p4', 'Performance', 'Heavy Hitter', 'Lifted 100 kg total', '💣'),
      _createAchievement('p5', 'Performance', 'Plank God', '3-minute plank', '🕒'),
      _createAchievement('p6', 'Performance', 'Speed Demon', 'Fastest mile', '🏎️'),
      _createAchievement('p7', 'Performance', 'Endurance Beast', '60-minute workout', '🔋'),
      _createAchievement('p8', 'Performance', 'Flexibility Pro', 'Touched toes', '🤸'),
      _createAchievement('p9', 'Performance', 'HIIT Hero', 'Completed 10 HIIT workouts', '🧨'),
      _createAchievement('p10', 'Performance', 'Cardio Crusher', 'Burned 500 kcal in a session', '🚴'),
    ]);

    // Progress Achievements
    _achievements.addAll([
      _createAchievement('pr1', 'Progress', 'Transformation Begins', 'Lost first kg', '📉'),
      _createAchievement('pr2', 'Progress', 'Fat Fighter', 'Reduced body fat %', '🔥'),
      _createAchievement('pr3', 'Progress', 'Macro Master', 'Balanced macros 5 days', '🥗'),
      _createAchievement('pr4', 'Progress', 'BMI Shift', 'Changed BMI category', '📏'),
      _createAchievement('pr5', 'Progress', 'Stress Slayer', 'Reduced stress trend', '🧘'),
    ]);

    // Exploration Achievements
    _achievements.addAll([
      _createAchievement('e1', 'Exploration', 'Explorer', 'Tried 3 workout types', '🗺️'),
      _createAchievement('e2', 'Exploration', 'Adventurer', 'Outdoor workout', '🌲'),
      _createAchievement('e3', 'Exploration', 'Yoga Rookie', 'First yoga class', '🧘‍♀️'),
      _createAchievement('e4', 'Exploration', 'Swim Champ', 'First swim tracked', '🏊'),
      _createAchievement('e5', 'Exploration', 'Trail Blazer', 'Trail run', '⛰️'),
      _createAchievement('e6', 'Exploration', 'Cyclist', 'First ride logged', '🚲'),
      _createAchievement('e7', 'Exploration', 'Bootcamp Grad', 'Finished program', '🎓'),
    ]);

    // Special / Rare Achievements
    _achievements.addAll([
      _createAchievement('r1', 'Special', 'Iron Will', '100 workouts', '⛓️'),
      _createAchievement('r2', 'Special', 'Marathoner', '42 km total', '🏁'),
      _createAchievement('r3', 'Special', 'Halfway There', 'Lost 10 kg', '🌗'),
      _createAchievement('r4', 'Special', 'Ultra Streaker', '180 days active', '💎'),
      _createAchievement('r5', 'Special', 'Hydration God', '100 water goals', '🔱'),
      _createAchievement('r6', 'Special', 'Comeback Kid', 'Returned after break', '🔙'),
      _createAchievement('r7', 'Special', 'New Year New Me', 'January challenge complete', '🎆'),
      _createAchievement('r8', 'Special', 'Holiday Hustler', 'Workout during holidays', '🎄'),
      _createAchievement('r9', 'Special', 'Perfect Month', 'Every daily goal hit', '🌟'),
    ]);

    notifyListeners();
  }

  Goal _createGoal(String id, String category, String title, String desc, double target, double current, {bool isBoolean = false}) {
    return Goal(
      id: id,
      category: category,
      title: title,
      description: desc,
      targetValue: target,
      currentValue: current,
      targetDate: DateTime.now().add(const Duration(days: 30)),
      isCompleted: current >= target,
      isBoolean: isBoolean,
    );
  }

  Achievement _createAchievement(String id, String category, String title, String desc, String icon, {bool isUnlocked = false}) {
    return Achievement(
      id: id,
      category: category,
      title: title,
      description: desc,
      icon: icon,
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? DateTime.now().subtract(const Duration(days: 1)) : null,
    );
  }

  void addProgressData(ProgressData data) {
    _progressData.add(data);
    notifyListeners();
  }

  void syncHealthData(int steps, int activeMinutes) {
    final now = DateTime.now();
    final todayIndex = _progressData.indexWhere((data) => 
        data.date.year == now.year && 
        data.date.month == now.month && 
        data.date.day == now.day);
    
    if (todayIndex != -1) {
      _progressData[todayIndex] = _progressData[todayIndex].copyWith(
        steps: steps,
        workoutTime: Duration(minutes: activeMinutes),
      );
    } else {
      _progressData.add(ProgressData(
        date: now,
        steps: steps,
        workoutTime: Duration(minutes: activeMinutes),
        caloriesBurned: 0,
      ));
    }
    notifyListeners();
  }

  void toggleGoalStatus(String goalId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final wasCompleted = goal.isCompleted;
      _goals[index] = goal.copyWith(
        isCompleted: !goal.isCompleted,
        currentValue: !goal.isCompleted ? goal.targetValue : 0,
      );
      if (!wasCompleted && _goals[index].isCompleted) {
        _completionController.add('Good job on completing your goal: ${goal.title}!');
      }
      notifyListeners();
    }
  }

  void updateGoal(String goalId, double currentValue) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final wasCompleted = goal.isCompleted;
      _goals[index] = goal.copyWith(
        currentValue: currentValue,
        isCompleted: currentValue >= goal.targetValue,
      );
      if (!wasCompleted && _goals[index].isCompleted) {
        _completionController.add('Congratulations! You\'ve reached your goal: ${goal.title}!');
      }
      notifyListeners();
    }
  }

  void unlockAchievement(String achievementId) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index != -1 && !_achievements[index].isUnlocked) {
      final achievement = _achievements[index];
      _achievements[index] = Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        category: achievement.category,
        icon: achievement.icon,
        unlockedDate: DateTime.now(),
        isUnlocked: true,
      );
      _completionController.add('Achievement Unlocked: ${achievement.icon} ${achievement.title}! Awesome work!');
      notifyListeners();
    }
  }
}
