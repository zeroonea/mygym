/// A training session on a given day.
class Workout {
  const Workout({
    this.id,
    required this.date,
    this.name,
    this.notes,
    this.completed = false,
  });

  final int? id;
  final DateTime date;
  final String? name;
  final String? notes;
  final bool completed;

  Workout copyWith({
    int? id,
    DateTime? date,
    String? name,
    String? notes,
    bool? completed,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.millisecondsSinceEpoch,
        'name': name,
        'notes': notes,
        'completed': completed ? 1 : 0,
      };

  factory Workout.fromMap(Map<String, Object?> map) => Workout(
        id: map['id'] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        name: map['name'] as String?,
        notes: map['notes'] as String?,
        completed: (map['completed'] as int? ?? 0) == 1,
      );
}
