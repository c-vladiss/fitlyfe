import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/rest_timer_widget.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final WorkoutRoutine routine;

  const ActiveWorkoutPage({super.key, required this.routine});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  DateTime? _startTime;
  bool _showRestTimer = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final exercises =
        workoutProvider.activeSession?.exercises ?? const <Exercise>[];

    return PopScope(
      // Leaving discards the session, so always ask first
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.primaryText),
            onPressed: () => _showExitConfirmation(context),
          ),
          title: Text(
            widget.routine.name,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showRestTimer ? Icons.timer_off : Icons.timer,
                color: AppTheme.accentGreen,
              ),
              onPressed: () {
                setState(() {
                  _showRestTimer = !_showRestTimer;
                });
              },
              tooltip: 'Toggle Rest Timer',
            ),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => _finishWorkout(context, workoutProvider),
              child: const Text(
                'FINISH',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Timer Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  final duration = DateTime.now().difference(_startTime!);
                  final minutes = duration.inMinutes.toString().padLeft(2, '0');
                  final seconds = (duration.inSeconds % 60).toString().padLeft(
                    2,
                    '0',
                  );
                  return Column(
                    children: [
                      const Text(
                        'ELAPSED TIME',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            if (_showRestTimer) ...[
              const Divider(color: AppTheme.cardBackground, thickness: 2),
              const RestTimerWidget(),
            ],

            const Divider(color: AppTheme.cardBackground, thickness: 2),

            // Exercises List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return _buildExerciseCard(exercises[index], workoutProvider);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddExerciseDialog(context, workoutProvider),
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: AppTheme.backgroundColor,
          icon: const Icon(Icons.add),
          label: const Text('EXERCISE'),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, WorkoutProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              Icon(
                exercise.sets.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
                color: exercise.sets.isEmpty
                    ? AppTheme.secondaryText
                    : AppTheme.accentGreen,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (exercise.sets.isEmpty)
            const Text(
              'No sets logged yet',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, set) in exercise.sets.indexed)
                  InputChip(
                    label: Text(
                      '${index + 1}: ${set.reps} reps${set.weight != null ? ' • ${_formatWeight(set.weight!)}kg' : ''}',
                    ),
                    backgroundColor: AppTheme.backgroundColor,
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    deleteIconColor: AppTheme.secondaryText,
                    deleteButtonTooltipMessage: 'Remove set',
                    onDeleted: () =>
                        provider.removeSetFromExercise(exercise.id, set.id),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAddSetDialog(context, provider, exercise),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.accentGreen,
                ),
                label: const Text(
                  'ADD SET',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showRestTimer = true;
                  });
                },
                icon: const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppTheme.accentGreen,
                ),
                label: const Text(
                  'START REST',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Leave workout?',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: const Text(
          'Your progress in this session will not be saved.',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Provider.of<WorkoutProvider>(
                context,
                listen: false,
              ).discardSession();
              final appState = Provider.of<AppState>(context, listen: false);
              appState.setPageIndex(2);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Navigate back
            },
            child: const Text(
              'LEAVE',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    setState(() => _isSaving = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await provider.endSession();

    // Ensure we switch to the Workout tab in the background
    appState.setPageIndex(2);
    final (message, color) = switch (result) {
      WorkoutSaveResult.saved => (
        'Workout completed! High five! ✋',
        AppTheme.accentGreen,
      ),
      WorkoutSaveResult.pending => (
        'Workout saved on this device. It will sync when you\'re back online.',
        AppTheme.accentYellow,
      ),
      WorkoutSaveResult.empty => (
        'No sets were logged, so nothing was saved.',
        AppTheme.secondaryText,
      ),
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
    navigator
        .pop(); // Return to whoever called it, but AppState will ensure tab 2 is active
  }

  Future<void> _showAddSetDialog(
    BuildContext context,
    WorkoutProvider provider,
    Exercise exercise,
  ) async {
    // Pre-fill with the previous set, which is usually repeated
    final previous = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final result = await showDialog<(int, double?)>(
      context: context,
      builder: (context) => _AddSetDialog(
        exerciseName: exercise.name,
        initialReps: previous?.reps,
        initialWeight: previous?.weight,
      ),
    );
    if (result == null) return;
    provider.addSetToExercise(exercise.id, result.$1, result.$2);
  }

  Future<void> _showAddExerciseDialog(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) provider.addExerciseToSession(trimmed);
  }

  static String _formatWeight(double weight) => weight == weight.roundToDouble()
      ? weight.toInt().toString()
      : weight.toString();
}

/// Asks for the name of an exercise to add to the session.
// Stateful so the text controller lives exactly as long as the dialog,
// including its closing animation.
class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: const Text('Add exercise'),
      content: TextField(
        key: const Key('exerciseNameField'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Exercise name'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

/// Asks for the reps and (optional) weight of one set.
class _AddSetDialog extends StatefulWidget {
  final String exerciseName;
  final int? initialReps;
  final double? initialWeight;

  const _AddSetDialog({
    required this.exerciseName,
    this.initialReps,
    this.initialWeight,
  });

  @override
  State<_AddSetDialog> createState() => _AddSetDialogState();
}

class _AddSetDialogState extends State<_AddSetDialog> {
  late final TextEditingController _reps = TextEditingController(
    text: widget.initialReps?.toString() ?? '',
  );
  late final TextEditingController _weight = TextEditingController(
    text: widget.initialWeight == null
        ? ''
        : _ActiveWorkoutPageState._formatWeight(widget.initialWeight!),
  );
  String? _error;

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _submit() {
    final reps = int.tryParse(_reps.text.trim());
    final weightText = _weight.text.trim().replaceAll(',', '.');
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    if (reps == null || reps < 0) {
      setState(() => _error = 'Enter the number of reps');
      return;
    }
    if (weightText.isNotEmpty && (weight == null || weight < 0)) {
      setState(() => _error = 'Enter a valid weight');
      return;
    }
    Navigator.pop(context, (reps, weight));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: Text(widget.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('repsField'),
            controller: _reps,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps'),
          ),
          TextField(
            key: const Key('weightField'),
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg, optional)',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.accentRed),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(onPressed: _submit, child: const Text('LOG SET')),
      ],
    );
  }
}
