import 'muscle_group.dart';

/// A single exercise in the library (e.g. "Bench Press").
class Exercise {
  const Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.isCustom = false,
    this.notes,
  });

  final int? id;
  final String name;

  /// Stored as [MuscleGroup.name].
  final String muscleGroup;
  final bool isCustom;
  final String? notes;

  MuscleGroup get group => MuscleGroup.fromName(muscleGroup);

  Exercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
    bool? isCustom,
    String? notes,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'is_custom': isCustom ? 1 : 0,
        'notes': notes,
      };

  factory Exercise.fromMap(Map<String, Object?> map) => Exercise(
        id: map['id'] as int?,
        name: map['name'] as String,
        muscleGroup: map['muscle_group'] as String,
        isCustom: (map['is_custom'] as int? ?? 0) == 1,
        notes: map['notes'] as String?,
      );
}
