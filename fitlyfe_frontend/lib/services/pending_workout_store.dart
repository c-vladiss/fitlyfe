import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps finished workouts that could not be saved to the backend yet, so they
/// survive an app restart and can be retried later.
///
/// Entries are the JSON form of `Input$LogWorkoutSessionInput`.
abstract class PendingWorkoutStore {
  Future<List<Map<String, dynamic>>> load();
  Future<void> save(List<Map<String, dynamic>> pending);
}

class SharedPreferencesPendingWorkoutStore implements PendingWorkoutStore {
  static const _key = 'pending_workout_sessions';

  @override
  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // A corrupt entry must not block the workout screen forever
      debugPrint('Discarding unreadable pending workouts: $e');
      return [];
    }
  }

  @override
  Future<void> save(List<Map<String, dynamic>> pending) async {
    final prefs = await SharedPreferences.getInstance();
    if (pending.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(pending));
    }
  }
}

/// Store that only lives in memory, for tests.
class InMemoryPendingWorkoutStore implements PendingWorkoutStore {
  List<Map<String, dynamic>> _pending;

  InMemoryPendingWorkoutStore([List<Map<String, dynamic>>? initial])
    : _pending = [...?initial];

  List<Map<String, dynamic>> get pending => List.unmodifiable(_pending);

  @override
  Future<List<Map<String, dynamic>>> load() async => [..._pending];

  @override
  Future<void> save(List<Map<String, dynamic>> pending) async {
    _pending = [...pending];
  }
}
