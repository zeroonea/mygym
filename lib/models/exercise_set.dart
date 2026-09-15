/// One logged set: a weight lifted for a number of reps.
class ExerciseSet {
  const ExerciseSet({
    this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.done = true,
  });

  final int? id;
  final int workoutExerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final bool done;

  /// Estimated one-rep max using the Epley formula.
  double get estimatedOneRepMax =>
      reps <= 1 ? weight : weight * (1 + reps / 30.0);

  double get volume => weight * reps;

  ExerciseSet copyWith({
    int? id,
    int? workoutExerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    bool? done,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'workout_exercise_id': workoutExerciseId,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'done': done ? 1 : 0,
      };

  factory ExerciseSet.fromMap(Map<String, Object?> map) => ExerciseSet(
        id: map['id'] as int?,
        workoutExerciseId: map['workout_exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        done: (map['done'] as int? ?? 1) == 1,
      );
}
