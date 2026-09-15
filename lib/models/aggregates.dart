import 'dart:math' as math;

import 'exercise.dart';
import 'exercise_set.dart';
import 'workout.dart';
import 'workout_exercise.dart';

/// An exercise within a workout together with its logged sets.
class SetGroup {
  const SetGroup({
    required this.workoutExercise,
    required this.exercise,
    required this.sets,
  });

  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<ExerciseSet> sets;

  double get volume => sets.fold(0, (sum, s) => sum + s.volume);

  double get bestWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce(math.max);

  double get bestOneRepMax => sets.isEmpty
      ? 0
      : sets.map((s) => s.estimatedOneRepMax).reduce(math.max);
}

/// A full workout expanded with its exercises and sets, ready for display.
class WorkoutDetail {
  const WorkoutDetail({required this.workout, required this.groups});

  final Workout workout;
  final List<SetGroup> groups;

  double get totalVolume => groups.fold(0, (sum, g) => sum + g.volume);

  int get totalSets => groups.fold(0, (sum, g) => sum + g.sets.length);

  int get exerciseCount => groups.length;
}

/// One data point in an exercise's progress history (one workout day).
class ProgressPoint {
  const ProgressPoint({
    required this.date,
    required this.bestWeight,
    required this.bestOneRepMax,
    required this.volume,
    required this.totalReps,
  });

  final DateTime date;
  final double bestWeight;
  final double bestOneRepMax;
  final double volume;
  final int totalReps;
}

/// Rolled-up numbers for a range of workouts (used on the dashboard).
class WorkoutSummary {
  const WorkoutSummary({
    required this.workoutCount,
    required this.totalVolume,
    required this.totalSets,
  });

  final int workoutCount;
  final double totalVolume;
  final int totalSets;
}
