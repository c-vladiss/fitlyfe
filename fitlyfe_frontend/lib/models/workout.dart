class Exercise {
  final String id;
  final String name;
  final List<Set> sets;
  final String? notes;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    this.notes,
  });
}

class Set {
  final String id;
  final int reps;
  final double? weight; // in kg
  final Duration? restTime;

  Set({required this.id, required this.reps, this.weight, this.restTime});
}

class WorkoutRoutine {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final Duration estimatedDuration;
  final String? description;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.estimatedDuration,
    this.description,
  });
}

class WorkoutSession {
  final String id;
  final String routineId;
  final String routineName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<Exercise> exercises;
  final double? caloriesBurned;

  /// False while a finished session is only stored on this device because
  /// saving it to the backend failed. It is retried on the next sync.
  final bool isSynced;

  WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.caloriesBurned,
    this.isSynced = true,
  });

  /// Number of sets logged across all exercises.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }
}
