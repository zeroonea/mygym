import 'package:flutter/foundation.dart';

import '../data/exercise_catalog.dart';
import '../data/gym_repository.dart';
import '../models/aggregates.dart';
import '../models/catalog_exercise.dart';
import '../models/workout.dart';

/// App-wide state: the exercise catalog plus the user's workouts. Screens
/// listen to this and call its methods; mutations reload caches and notify.
class GymProvider extends ChangeNotifier {
  GymProvider({ExerciseCatalog? catalog, GymRepository? repository})
      : catalog = catalog ?? ExerciseCatalog() {
    this.repository = repository ?? GymRepository(catalog: this.catalog);
  }

  final ExerciseCatalog catalog;
  late final GymRepository repository;

  bool _loading = true;
  bool get loading => _loading;

  List<Workout> _workouts = [];
  List<Workout> get workouts => List.unmodifiable(_workouts);

  WorkoutSummary _weekSummary =
      const WorkoutSummary(workoutCount: 0, totalVolume: 0, totalSets: 0);
  WorkoutSummary get weekSummary => _weekSummary;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _reloadCatalog();
    await _reloadWorkouts(notify: false);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _reloadCatalog();
    await _reloadWorkouts();
  }

  Future<void> _reloadCatalog() async {
    final custom = await repository.getCustomExercises();
    await catalog.load(custom: custom);
  }

  Future<void> _reloadWorkouts({bool notify = true}) async {
    _workouts = await repository.getWorkouts();
    _weekSummary = await repository.summarySince(_startOfWeek());
    if (notify) notifyListeners();
  }

  // --- Custom exercises ----------------------------------------------------

  Future<void> saveCustomExercise(CatalogExercise exercise) async {
    await repository.saveCustomExercise(exercise);
    await _reloadCatalog();
    notifyListeners();
  }

  Future<void> deleteCustomExercise(String id) async {
    await repository.deleteCustomExercise(id);
    await _reloadCatalog();
    notifyListeners();
  }

  // --- Workouts ------------------------------------------------------------

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

  Future<void> notifyWorkoutChanged() => _reloadWorkouts();

  static DateTime _startOfWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }
}
