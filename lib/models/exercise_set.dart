/// One logged set: a weight lifted for a number of reps.
///
/// [weight] is the external load. For bodyweight exercises, [bodyWeight] holds
/// the lifter's bodyweight snapshot at the time, so volume and 1RM reflect the
/// full load moved (bodyweight + any added weight) and stay accurate as the
/// user's bodyweight changes over time.
class ExerciseSet {
  const ExerciseSet({
    this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.done = true,
    this.bodyWeight,
    this.createdAt,
  });

  final int? id;
  final int workoutExerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final bool done;

  /// Bodyweight snapshot (kg) for bodyweight exercises; null for weighted ones.
  final double? bodyWeight;

  /// When the set was logged (used to show rest between sets).
  final DateTime? createdAt;

  /// True when this set counts bodyweight toward the load.
  bool get isBodyweight => bodyWeight != null;

  /// The total load moved: external weight plus any bodyweight snapshot.
  double get effectiveWeight => weight + (bodyWeight ?? 0);

  /// Estimated one-rep max using the Epley formula, on the effective load.
  double get estimatedOneRepMax =>
      reps <= 1 ? effectiveWeight : effectiveWeight * (1 + reps / 30.0);

  double get volume => effectiveWeight * reps;

  ExerciseSet copyWith({
    int? id,
    int? workoutExerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    bool? done,
    double? bodyWeight,
    DateTime? createdAt,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'workout_exercise_id': workoutExerciseId,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'done': done ? 1 : 0,
        'body_weight': bodyWeight,
        'created_at': createdAt?.millisecondsSinceEpoch,
      };

  factory ExerciseSet.fromMap(Map<String, Object?> map) => ExerciseSet(
        id: map['id'] as int?,
        workoutExerciseId: map['workout_exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        done: (map['done'] as int? ?? 1) == 1,
        bodyWeight: (map['body_weight'] as num?)?.toDouble(),
        createdAt: map['created_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
