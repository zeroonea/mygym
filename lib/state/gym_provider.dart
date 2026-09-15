import 'package:flutter/foundation.dart';

import '../data/gym_repository.dart';
import '../models/aggregates.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

/// App-wide state backed by [GymRepository]. Screens listen to this and call
/// its methods; each mutation reloads the affected caches and notifies.
class GymProvider extends ChangeNotifier {
  GymProvider({GymRepository? repository})
      : repository = repository ?? GymRepository();

  final GymRepository repository;

  bool _loading = true;
  bool get loading => _loading;

  List<Exercise> _exercises = [];
  List<Exercise> get exercises => List.unmodifiable(_exercises);

  List<Workout> _workouts = [];
  List<Workout> get workouts => List.unmodifiable(_workouts);

  WorkoutSummary _weekSummary =
      const WorkoutSummary(workoutCount: 0, totalVolume: 0, totalSets: 0);
  WorkoutSummary get weekSummary => _weekSummary;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _reloadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => _reloadAll(notify: true);

  Future<void> _reloadAll({bool notify = false}) async {
    _exercises = await repository.getExercises();
    _workouts = await repository.getWorkouts();
    _weekSummary = await repository.summarySince(_startOfWeek());
    if (notify) notifyListeners();
  }

  Future<void> _reloadWorkouts() async {
    _workouts = await repository.getWorkouts();
    _weekSummary = await repository.summarySince(_startOfWeek());
    notifyListeners();
  }

  Future<void> _reloadExercises() async {
    _exercises = await repository.getExercises();
    notifyListeners();
  }

  // --- Exercises -----------------------------------------------------------

  Future<void> addExercise(Exercise exercise) async {
    await repository.addExercise(exercise);
    await _reloadExercises();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await repository.updateExercise(exercise);
    await _reloadExercises();
  }

  Future<void> deleteExercise(int id) async {
    await repository.deleteExercise(id);
    await _reloadExercises();
  }

  // --- Workouts ------------------------------------------------------------

  /// Creates a new workout and returns its id.
  Future<int> startWorkout({String? name}) async {
    final id = await repository.createWorkout(name: name);
    await _reloadWorkouts();
    return id;
  }

  Future<void> deleteWorkout(int id) async {
    await repository.deleteWorkout(id);
    await _reloadWorkouts();
  }

  Future<void> saveWorkout(Workout workout) async {
    await repository.updateWorkout(workout);
    await _reloadWorkouts();
  }

  /// Called by the workout detail screen after it mutates sets/exercises so
  /// dashboard totals stay in sync.
  Future<void> notifyWorkoutChanged() => _reloadWorkouts();

  static DateTime _startOfWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday as the first day of the week.
    return today.subtract(Duration(days: today.weekday - 1));
  }
}
