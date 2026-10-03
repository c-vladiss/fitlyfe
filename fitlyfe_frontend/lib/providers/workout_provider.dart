import 'package:flutter/foundation.dart';
import 'package:fitlyfe_frontend/graphql/schema.graphql.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/services/pending_workout_store.dart';
import 'package:uuid/uuid.dart';

/// Outcome of finishing a workout.
enum WorkoutSaveResult {
  /// Saved to the backend.
  saved,

  /// Saving failed (e.g. offline); kept on the device and retried on next sync.
  pending,

  /// Nothing was logged, so there was nothing to save.
  empty,
}

class WorkoutProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;
  final PendingWorkoutStore _pendingStore;

  final List<WorkoutRoutine> _routines = [];
  WorkoutRoutine? _currentRoutine;
  WorkoutSession? _activeSession;

  /// Sessions saved on the backend, newest first.
  List<WorkoutSession> _savedSessions = [];

  /// Finished sessions not saved yet, as `Input$LogWorkoutSessionInput` JSON.
  List<Map<String, dynamic>> _pendingInputs = [];
  bool _pendingLoaded = false;

  bool _isLoading = false;
  String? _error;
  Future<void>? _syncInFlight;

  List<WorkoutRoutine> get routines => _routines;
  WorkoutRoutine? get currentRoutine => _currentRoutine;
  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All finished sessions, including ones still waiting to be saved, newest first.
  List<WorkoutSession> get sessions {
    final all = [
      ..._pendingInputs.map(_sessionFromPendingInput),
      ..._savedSessions,
    ];
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  int get pendingCount => _pendingInputs.length;

  WorkoutProvider({
    GraphQLService? graphQLService,
    PendingWorkoutStore? pendingStore,
  }) : _graphQLService = graphQLService ?? GraphQLService(),
       _pendingStore = pendingStore ?? SharedPreferencesPendingWorkoutStore() {
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

    // Goals are stored as keys ("lose_weight", onboarding and profile) and,
    // in older data, as labels ("Lose Weight"); accept both.
    switch (goal.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'lose_weight':
        _addWeightLossRoutines();
        break;
      case 'build_muscle':
        _addMuscleBuildingRoutines();
        break;
      case 'improve_endurance':
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
        description:
            'High intensity interval training to maximize calorie burn.',
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
        description:
            'Build a thick and wide back with these pulling movements.',
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
        description:
            'Long sets with short rest periods to build lasting endurance.',
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
        description:
            'High repetition movements to improve metabolic conditioning.',
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
      id: const Uuid().v4(),
      routineId: routine.id,
      routineName: routine.name,
      startTime: DateTime.now(),
      exercises: routine.exercises
          .map(
            (e) => Exercise(id: e.id, name: e.name, sets: [], notes: e.notes),
          )
          .toList(),
    );
    notifyListeners();
  }

  /// Drops the active session without saving it.
  void discardSession() {
    _activeSession = null;
    notifyListeners();
  }

  /// Finishes the active session and saves it to the backend.
  ///
  /// Exercises without sets are left out. If saving fails the session is kept
  /// on the device and retried by [syncSessions], so a workout is never lost.
  Future<WorkoutSaveResult> endSession() async {
    final session = _activeSession;
    if (session == null) return WorkoutSaveResult.empty;
    _activeSession = null;

    final exercises = session.exercises
        .where((e) => e.sets.isNotEmpty)
        .toList();
    if (exercises.isEmpty) {
      notifyListeners();
      return WorkoutSaveResult.empty;
    }

    final input = Input$LogWorkoutSessionInput(
      // The local id doubles as the idempotency key, so retries can't duplicate it
      clientId: session.id,
      startedAt: session.startTime.toUtc().toIso8601String(),
      endedAt: DateTime.now().toUtc().toIso8601String(),
      workoutType: session.routineName,
      caloriesBurned: session.caloriesBurned?.round(),
      exercises: exercises
          .map(
            (e) => Input$LoggedExerciseInput(
              name: e.name,
              notes: e.notes,
              sets: e.sets
                  .map(
                    (s) =>
                        Input$LoggedSetInput(reps: s.reps, weightKg: s.weight),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    await _ensurePendingLoaded();
    _pendingInputs = [..._pendingInputs, input.toJson()];
    await _pendingStore.save(_pendingInputs);
    notifyListeners();

    await syncSessions();
    return _pendingInputs.any((p) => p['clientId'] == session.id)
        ? WorkoutSaveResult.pending
        : WorkoutSaveResult.saved;
  }

  /// Loads the session history from the backend, after first retrying any
  /// sessions that are still waiting to be saved.
  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      await syncSessions();
      final remote = await _graphQLService.getWorkoutSessions();
      _savedSessions = remote.map(_sessionFromRemote).toList();
      _error = null;
    } catch (e) {
      debugPrint('Error loading workout sessions: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads sessions waiting to be saved, oldest first. Stops at the first
  /// failure so their order is kept. Concurrent calls share one upload.
  Future<void> syncSessions() =>
      _syncInFlight ??= _uploadPending().whenComplete(() {
        _syncInFlight = null;
      });

  Future<void> _uploadPending() async {
    await _ensurePendingLoaded();
    while (_pendingInputs.isNotEmpty) {
      final next = _pendingInputs.first;
      try {
        final saved = await _graphQLService.logWorkoutSession(
          Input$LogWorkoutSessionInput.fromJson(next),
        );
        _pendingInputs = _pendingInputs.skip(1).toList();
        await _pendingStore.save(_pendingInputs);
        _savedSessions = [
          _sessionFromRemote(saved),
          ..._savedSessions.where((s) => s.id != saved.id),
        ];
        _error = null;
        notifyListeners();
      } catch (e) {
        debugPrint('Could not save workout session, will retry later: $e');
        _error = e.toString();
        notifyListeners();
        return;
      }
    }
  }

  Future<void> _ensurePendingLoaded() async {
    if (_pendingLoaded) return;
    final stored = await _pendingStore.load();
    // Keep anything queued while the store was loading
    _pendingInputs = [...stored, ..._pendingInputs];
    _pendingLoaded = true;
  }

  /// Deletes a saved session, or drops one that was never saved.
  Future<bool> deleteSession(String id) async {
    await _ensurePendingLoaded();
    final pendingIndex = _pendingInputs.indexWhere((p) => p['clientId'] == id);
    if (pendingIndex != -1) {
      _pendingInputs = [..._pendingInputs]..removeAt(pendingIndex);
      await _pendingStore.save(_pendingInputs);
      notifyListeners();
      return true;
    }

    try {
      final deleted = await _graphQLService.deleteWorkoutSession(id);
      if (deleted) {
        _savedSessions = _savedSessions.where((s) => s.id != id).toList();
        notifyListeners();
      }
      return deleted;
    } catch (e) {
      debugPrint('Error deleting workout session: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void addExerciseToSession(String exerciseName) {
    final session = _activeSession;
    if (session == null) return;
    _activeSession = _copySession(
      session,
      exercises: [
        ...session.exercises,
        Exercise(id: const Uuid().v4(), name: exerciseName, sets: []),
      ],
    );
    notifyListeners();
  }

  void addSetToExercise(String exerciseId, int reps, double? weight) {
    _updateExercise(
      exerciseId,
      (exercise) => [
        ...exercise.sets,
        Set(id: const Uuid().v4(), reps: reps, weight: weight),
      ],
    );
  }

  void removeSetFromExercise(String exerciseId, String setId) {
    _updateExercise(
      exerciseId,
      (exercise) => exercise.sets.where((s) => s.id != setId).toList(),
    );
  }

  void _updateExercise(
    String exerciseId,
    List<Set> Function(Exercise) newSets,
  ) {
    final session = _activeSession;
    if (session == null) return;
    final index = session.exercises.indexWhere((e) => e.id == exerciseId);
    if (index == -1) return;

    final exercise = session.exercises[index];
    final exercises = [...session.exercises];
    exercises[index] = Exercise(
      id: exercise.id,
      name: exercise.name,
      sets: newSets(exercise),
      notes: exercise.notes,
    );
    _activeSession = _copySession(session, exercises: exercises);
    notifyListeners();
  }

  WorkoutSession _copySession(
    WorkoutSession s, {
    required List<Exercise> exercises,
  }) {
    return WorkoutSession(
      id: s.id,
      routineId: s.routineId,
      routineName: s.routineName,
      startTime: s.startTime,
      endTime: s.endTime,
      exercises: exercises,
      caloriesBurned: s.caloriesBurned,
    );
  }

  void addRoutine(WorkoutRoutine routine) {
    _routines.add(routine);
    notifyListeners();
  }

  // ── Mapping ─────────────────────────────────────────────────────────────

  static WorkoutSession _sessionFromRemote(WorkoutSessionResult remote) {
    final start = _parseTimestamp(remote.startedAt) ?? DateTime.now();
    return WorkoutSession(
      id: remote.id,
      routineId: '',
      routineName: remote.workoutType ?? 'Workout',
      startTime: start,
      endTime: _parseTimestamp(remote.endedAt),
      caloriesBurned: remote.caloriesBurned?.toDouble(),
      exercises: remote.exercises
          .map(
            (e) => Exercise(
              id: e.id,
              name: e.exercise.name,
              notes: e.notes,
              sets: e.sets
                  .map(
                    (s) => Set(id: s.id, reps: s.reps ?? 0, weight: s.weightKg),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  static WorkoutSession _sessionFromPendingInput(Map<String, dynamic> json) {
    final input = Input$LogWorkoutSessionInput.fromJson(json);
    return WorkoutSession(
      id: input.clientId ?? '',
      routineId: '',
      routineName: input.workoutType ?? 'Workout',
      startTime: DateTime.parse(input.startedAt).toLocal(),
      endTime: DateTime.parse(input.endedAt).toLocal(),
      caloriesBurned: input.caloriesBurned?.toDouble(),
      isSynced: false,
      exercises: input.exercises.indexed
          .map(
            (entry) => Exercise(
              id: '${input.clientId}-${entry.$1}',
              name: entry.$2.name,
              notes: entry.$2.notes,
              sets: entry.$2.sets.indexed
                  .map(
                    (set) => Set(
                      id: '${input.clientId}-${entry.$1}-${set.$1}',
                      reps: set.$2.reps ?? 0,
                      weight: set.$2.weightKg,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  /// The backend returns UTC timestamps; show them in local time.
  static DateTime? _parseTimestamp(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toLocal();
}
