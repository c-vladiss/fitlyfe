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

  Set({
    required this.id,
    required this.reps,
    this.weight,
    this.restTime,
  });
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

  WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.caloriesBurned,
  });

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }
}
