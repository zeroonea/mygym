/// Links an [Exercise] into a [Workout], preserving its order in the session.
class WorkoutExercise {
  const WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.position,
  });

  final int? id;
  final int workoutId;
  final int exerciseId;
  final int position;

  WorkoutExercise copyWith({
    int? id,
    int? workoutId,
    int? exerciseId,
    int? position,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'position': position,
      };

  factory WorkoutExercise.fromMap(Map<String, Object?> map) => WorkoutExercise(
        id: map['id'] as int?,
        workoutId: map['workout_id'] as int,
        exerciseId: map['exercise_id'] as int,
        position: map['position'] as int,
      );
}
