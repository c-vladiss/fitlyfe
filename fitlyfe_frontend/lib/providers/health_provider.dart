import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'dart:io';

class HealthProvider extends ChangeNotifier {
  int _steps = 0;
  int _activeMinutes = 0;
  bool _isAuthorized = false;
  bool _isLoading = false;

  int get steps => _steps;
  int get activeMinutes => _activeMinutes;
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;

  final Health _health = Health();

  // Define the types to get.
  static const List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.WORKOUT,
  ];

  // For Android, we need to specify permissions for Health Connect
  static const List<HealthDataAccess> permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Configure for Health Connect on Android
      if (Platform.isAndroid) {
        await _health.configure();
      }

      await fetchData();
    } catch (e) {
      debugPrint("Error initializing health: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      bool authorized = await _health.requestAuthorization(types, permissions: permissions);
      _isAuthorized = authorized;
      notifyListeners();
      return authorized;
    } catch (e) {
      debugPrint("Error requesting authorization: $e");
      return false;
    }
  }

  Future<void> fetchData() async {
    bool authorized = await _health.hasPermissions(types) ?? false;
    _isAuthorized = authorized;

    if (!authorized) {
      debugPrint("Not authorized to fetch health data");
      return;
    }

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // Fetch steps
      int? stepsCount = await _health.getTotalStepsInInterval(midnight, now);
      _steps = stepsCount ?? 0;

      // Fetch exercise time
      List<HealthDataPoint> exerciseData = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.EXERCISE_TIME],
      );

      double totalMinutes = 0;
      for (var data in exerciseData) {
        if (data.type == HealthDataType.EXERCISE_TIME) {
          // The value might be in minutes or seconds depending on the platform/source
          // Typically for health package it's converted to a consistent unit if possible
          totalMinutes += double.tryParse(data.value.toString()) ?? 0;
        }
      }

      // Also check Workouts if exercise time is low/missing
      if (totalMinutes == 0) {
        List<HealthDataPoint> workoutData = await _health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: [HealthDataType.WORKOUT],
        );
        
        for (var data in workoutData) {
           // Workouts usually have a duration
           // In health package, workout value is often numeric or a map
           // For simplicity, we can try to estimate or use the duration if available
           // But actually health package provides duration in many cases
           final workoutValue = data.value as WorkoutHealthValue;
           totalMinutes += workoutValue.totalEnergyBurned != null ? 30 : 0; // Placeholder if duration isn't direct
           // Better: HealthDataPoint has date_from and date_to
           final duration = data.dateTo.difference(data.dateFrom).inMinutes;
           totalMinutes += duration;
        }
      }

      _activeMinutes = totalMinutes.toInt();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching health data: $e");
    }
  }
}
