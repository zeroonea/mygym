/// Links a catalog exercise into a [Workout], preserving its order. A snapshot
/// of the exercise name and group is stored alongside so history survives even
/// if the catalog changes.
class WorkoutExercise {
  const WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.position,
  });

  final int? id;
  final int workoutId;
  final String exerciseId;
  final int position;

  factory WorkoutExercise.fromMap(Map<String, Object?> map) => WorkoutExercise(
        id: map['id'] as int?,
        workoutId: map['workout_id'] as int,
        exerciseId: map['exercise_id'] as String,
        position: map['position'] as int,
      );
}
