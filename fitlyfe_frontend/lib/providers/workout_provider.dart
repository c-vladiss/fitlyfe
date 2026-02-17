import 'package:flutter/foundation.dart';
import 'package:fitlyfe_frontend/models/workout.dart';

class WorkoutProvider extends ChangeNotifier {
  final List<WorkoutRoutine> _routines = [];
  final List<WorkoutSession> _sessions = [];
  WorkoutRoutine? _currentRoutine;
  WorkoutSession? _activeSession;

  List<WorkoutRoutine> get routines => _routines;
  List<WorkoutSession> get sessions => _sessions;
  WorkoutRoutine? get currentRoutine => _currentRoutine;
  WorkoutSession? get activeSession => _activeSession;

  WorkoutProvider() {
    _initializeDefaultRoutines();
  }

  void _initializeDefaultRoutines() {
    // Add a basic default routine
    final defaultRoutine = WorkoutRoutine(
      id: 'default_1',
      name: 'Full Body Intro',
      estimatedDuration: const Duration(minutes: 45),
      exercises: [
        Exercise(id: 'e1', name: 'Bodyweight Squats', sets: []),
        Exercise(id: 'e2', name: 'Pushups', sets: []),
        Exercise(id: 'e3', name: 'Plank', sets: []),
        Exercise(id: 'e4', name: 'Walking Lunges', sets: []),
      ],
    );
    _routines.add(defaultRoutine);
    _currentRoutine = defaultRoutine;
    notifyListeners();
  }

  void initializeWorkoutsForGoal(String goal) {
    _routines.clear();
    
    switch (goal) {
      case 'Lose Weight':
        _addWeightLossRoutines();
        break;
      case 'Build Muscle':
        _addMuscleBuildingRoutines();
        break;
      case 'Improve Endurance':
        _addEnduranceRoutines();
        break;
      default:
        _addGeneralFitnessRoutines();
    }

    if (_routines.isNotEmpty) {
      _currentRoutine = _routines.first;
    }
    notifyListeners();
  }

  void _addWeightLossRoutines() {
    _routines.addAll([
      WorkoutRoutine(
        id: 'lw_1',
        name: 'Fat Burning HIIT',
        description: 'High intensity interval training to maximize calorie burn.',
        estimatedDuration: const Duration(minutes: 30),
        exercises: [
          Exercise(id: 'hiit1', name: 'Burpees', sets: []),
          Exercise(id: 'hiit2', name: 'Mountain Climbers', sets: []),
          Exercise(id: 'hiit3', name: 'Jump Squats', sets: []),
          Exercise(id: 'hiit4', name: 'High Knees', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'lw_2',
        name: 'Full Body Circuit',
        description: 'Keep your heart rate up with this continuous circuit.',
        estimatedDuration: const Duration(minutes: 40),
        exercises: [
          Exercise(id: 'circ1', name: 'Kettlebell Swings', sets: []),
          Exercise(id: 'circ2', name: 'Box Jumps', sets: []),
          Exercise(id: 'circ3', name: 'Dumbbell Thrusters', sets: []),
          Exercise(id: 'circ4', name: 'Medicine Ball Slams', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'lw_3',
        name: 'Tabata Torcher',
        description: '20 seconds on, 10 seconds off. Maximum intensity.',
        estimatedDuration: const Duration(minutes: 20),
        exercises: [
          Exercise(id: 'tab1', name: 'Sprints', sets: []),
          Exercise(id: 'tab2', name: 'Pushups', sets: []),
          Exercise(id: 'tab3', name: 'Jumping Jacks', sets: []),
          Exercise(id: 'tab4', name: 'Plank Jacks', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'lw_4',
        name: 'No Equipment Cardio',
        description: 'Burn calories anywhere with no gear needed.',
        estimatedDuration: const Duration(minutes: 35),
        exercises: [
          Exercise(id: 'nec1', name: 'Shadow Boxing', sets: []),
          Exercise(id: 'nec2', name: 'Run in Place', sets: []),
          Exercise(id: 'nec3', name: 'Butt Kicks', sets: []),
          Exercise(id: 'nec4', name: 'Skaters', sets: []),
          Exercise(id: 'nec5', name: 'Bicycle Crunches', sets: []),
        ],
      ),
    ]);
  }

  void _addMuscleBuildingRoutines() {
    _routines.addAll([
      WorkoutRoutine(
        id: 'bm_1',
        name: 'Push Day (Chest/Triceps)',
        description: 'Focus on growth for your pushing muscle groups.',
        estimatedDuration: const Duration(minutes: 60),
        exercises: [
          Exercise(id: 'push1', name: 'Incline Bench Press', sets: []),
          Exercise(id: 'push2', name: 'Dumbbell Shoulder Press', sets: []),
          Exercise(id: 'push3', name: 'Tricep Rope Pushdowns', sets: []),
          Exercise(id: 'push4', name: 'Lateral Raises', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'bm_2',
        name: 'Pull Day (Back/Biceps)',
        description: 'Build a thick and wide back with these pulling movements.',
        estimatedDuration: const Duration(minutes: 60),
        exercises: [
          Exercise(id: 'pull1', name: 'Lat Pulldowns', sets: []),
          Exercise(id: 'pull2', name: 'Seated Cable Rows', sets: []),
          Exercise(id: 'pull3', name: 'Barbell Bicep Curls', sets: []),
          Exercise(id: 'pull4', name: 'Face Pulls', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'bm_3',
        name: 'Leg Day Destruction',
        description: 'Don\'t skip leg day! Comprehensive lower body workout.',
        estimatedDuration: const Duration(minutes: 70),
        exercises: [
          Exercise(id: 'leg1', name: 'Barbell Squats', sets: []),
          Exercise(id: 'leg2', name: 'Romanian Deadlifts', sets: []),
          Exercise(id: 'leg3', name: 'Leg Press', sets: []),
          Exercise(id: 'leg4', name: 'Bulgarian Split Squats', sets: []),
          Exercise(id: 'leg5', name: 'Calf Raises', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'bm_4',
        name: 'Arm Farm',
        description: 'Suns out guns out. Dedicated arm hypertrophy session.',
        estimatedDuration: const Duration(minutes: 45),
        exercises: [
          Exercise(id: 'arm1', name: 'Skull Crushers', sets: []),
          Exercise(id: 'arm2', name: 'Preacher Curls', sets: []),
          Exercise(id: 'arm3', name: 'Tricep Dips', sets: []),
          Exercise(id: 'arm4', name: 'Hammer Curls', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'bm_5',
        name: 'Shoulder Boulder',
        description: 'Build broad delts for that V-taper look.',
        estimatedDuration: const Duration(minutes: 50),
        exercises: [
          Exercise(id: 'sh1', name: 'Overhead Press', sets: []),
          Exercise(id: 'sh2', name: 'Lateral Raises', sets: []),
          Exercise(id: 'sh3', name: 'Front Raises', sets: []),
          Exercise(id: 'sh4', name: 'Rear Delt Flyes', sets: []),
          Exercise(id: 'sh5', name: 'Shrugs', sets: []),
        ],
      ),
    ]);
  }

  void _addEnduranceRoutines() {
    _routines.addAll([
      WorkoutRoutine(
        id: 'ie_1',
        name: 'Stamina Power Circuit',
        description: 'Long sets with short rest periods to build lasting endurance.',
        estimatedDuration: const Duration(minutes: 50),
        exercises: [
          Exercise(id: 'end1', name: 'Jump Rope (3 mins)', sets: []),
          Exercise(id: 'end2', name: 'Battle Ropes', sets: []),
          Exercise(id: 'end3', name: 'Assault Bike Sprint', sets: []),
          Exercise(id: 'end4', name: 'Rowing Machine', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'ie_2',
        name: 'Bodyweight Marathon',
        description: 'High repetition movements to improve metabolic conditioning.',
        estimatedDuration: const Duration(minutes: 45),
        exercises: [
          Exercise(id: 'end5', name: 'Air Squats (50 reps)', sets: []),
          Exercise(id: 'end6', name: 'Walking Lunges', sets: []),
          Exercise(id: 'end7', name: 'Bear Crawls', sets: []),
          Exercise(id: 'end8', name: 'Step Ups', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'ie_3',
        name: 'Core & Cardio Hybrid',
        description: 'Mix of abdominal work and cardiovascular spikes.',
        estimatedDuration: const Duration(minutes: 40),
        exercises: [
          Exercise(id: 'cc1', name: 'Plank (1 min)', sets: []),
          Exercise(id: 'cc2', name: 'Running (5 mins)', sets: []),
          Exercise(id: 'cc3', name: 'Russian Twists', sets: []),
          Exercise(id: 'cc4', name: 'Rowing (5 mins)', sets: []),
          Exercise(id: 'cc5', name: 'Leg Raises', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'ie_4',
        name: 'Runners Strength',
        description: 'Improve leg durability for long distance running.',
        estimatedDuration: const Duration(minutes: 45),
        exercises: [
          Exercise(id: 'rs1', name: 'Single Leg Deadlifts', sets: []),
          Exercise(id: 'rs2', name: 'Step Ups', sets: []),
          Exercise(id: 'rs3', name: 'Calf Raises', sets: []),
          Exercise(id: 'rs4', name: 'Side Planks', sets: []),
        ],
      ),
    ]);
  }

  void _addGeneralFitnessRoutines() {
    _routines.addAll([
      WorkoutRoutine(
        id: 'sf_1',
        name: 'Balanced Athlete',
        description: 'A mix of strength and conditioning for overall health.',
        estimatedDuration: const Duration(minutes: 45),
        exercises: [
          Exercise(id: 'gen1', name: 'Deadlifts', sets: []),
          Exercise(id: 'gen2', name: 'Overhead Press', sets: []),
          Exercise(id: 'gen3', name: 'Pull Ups', sets: []),
          Exercise(id: 'gen4', name: 'Farmers Walk', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'sf_2',
        name: 'Morning Mobility',
        description: 'Wake up your body with this light movement flow.',
        estimatedDuration: const Duration(minutes: 20),
        exercises: [
          Exercise(id: 'mob1', name: 'Cat-Cow Stretch', sets: []),
          Exercise(id: 'mob2', name: 'World\'s Greatest Stretch', sets: []),
          Exercise(id: 'mob3', name: 'Deep Squat Hold', sets: []),
          Exercise(id: 'mob4', name: 'Thoracic Rotations', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'sf_3',
        name: 'Quick Core Blaster',
        description: '15 minutes of focused abdominal work.',
        estimatedDuration: const Duration(minutes: 15),
        exercises: [
          Exercise(id: 'core1', name: 'Crunches', sets: []),
          Exercise(id: 'core2', name: 'Leg Raises', sets: []),
          Exercise(id: 'core3', name: 'Plank', sets: []),
          Exercise(id: 'core4', name: 'Dead Bug', sets: []),
        ],
      ),
      WorkoutRoutine(
        id: 'sf_4',
        name: 'Yoga Flow',
        description: 'Relax and recover with this beginner yoga sequence.',
        estimatedDuration: const Duration(minutes: 30),
        exercises: [
          Exercise(id: 'yoga1', name: 'Downward Dog', sets: []),
          Exercise(id: 'yoga2', name: 'Warrior II', sets: []),
          Exercise(id: 'yoga3', name: 'Triangle Pose', sets: []),
          Exercise(id: 'yoga4', name: 'Child\'s Pose', sets: []),
        ],
      ),
    ]);
  }

  void setCurrentRoutine(WorkoutRoutine routine) {
    _currentRoutine = routine;
    notifyListeners();
  }

  void startSession(WorkoutRoutine routine) {
    _activeSession = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routineId: routine.id,
      routineName: routine.name,
      startTime: DateTime.now(),
      exercises: routine.exercises.map((e) => Exercise(
        id: e.id,
        name: e.name,
        sets: [],
        notes: e.notes,
      )).toList(),
    );
    notifyListeners();
  }

  void endSession() {
    if (_activeSession != null) {
      final endedSession = WorkoutSession(
        id: _activeSession!.id,
        routineId: _activeSession!.routineId,
        routineName: _activeSession!.routineName,
        startTime: _activeSession!.startTime,
        endTime: DateTime.now(),
        exercises: _activeSession!.exercises,
        caloriesBurned: _activeSession!.caloriesBurned,
      );
      _sessions.add(endedSession);
      _activeSession = null;
      notifyListeners();
    }
  }

  void addExerciseToSession(String exerciseName) {
    if (_activeSession != null) {
      final newExercise = Exercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: exerciseName,
        sets: [],
      );
      final updatedExercises = List<Exercise>.from(_activeSession!.exercises)
        ..add(newExercise);
      _activeSession = WorkoutSession(
        id: _activeSession!.id,
        routineId: _activeSession!.routineId,
        routineName: _activeSession!.routineName,
        startTime: _activeSession!.startTime,
        endTime: _activeSession!.endTime,
        exercises: updatedExercises,
        caloriesBurned: _activeSession!.caloriesBurned,
      );
      notifyListeners();
    }
  }

  void addSetToExercise(String exerciseId, int reps, double? weight) {
    if (_activeSession != null) {
      final exerciseIndex = _activeSession!.exercises.indexWhere(
        (e) => e.id == exerciseId,
      );
      if (exerciseIndex != -1) {
        final exercise = _activeSession!.exercises[exerciseIndex];
        final newSet = Set(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          reps: reps,
          weight: weight,
        );
        final updatedSets = List<Set>.from(exercise.sets)..add(newSet);
        final updatedExercise = Exercise(
          id: exercise.id,
          name: exercise.name,
          sets: updatedSets,
          notes: exercise.notes,
        );
        final updatedExercises = List<Exercise>.from(_activeSession!.exercises);
        updatedExercises[exerciseIndex] = updatedExercise;
        _activeSession = WorkoutSession(
          id: _activeSession!.id,
          routineId: _activeSession!.routineId,
          routineName: _activeSession!.routineName,
          startTime: _activeSession!.startTime,
          endTime: _activeSession!.endTime,
          exercises: updatedExercises,
          caloriesBurned: _activeSession!.caloriesBurned,
        );
        notifyListeners();
      }
    }
  }

  void addRoutine(WorkoutRoutine routine) {
    _routines.add(routine);
    notifyListeners();
  }
}

