/// Biological sex, used by the BMR and body-fat formulas.
enum Sex {
  male('Male'),
  female('Female');

  const Sex(this.label);

  final String label;

  static Sex fromName(String? name) =>
      Sex.values.firstWhere((s) => s.name == name, orElse: () => Sex.male);
}

/// Daily activity level → TDEE multiplier (applied to BMR).
enum ActivityLevel {
  sedentary('Sedentary', 'Little or no exercise', 1.2),
  light('Light', 'Exercise 1–3 days/week', 1.375),
  moderate('Moderate', 'Exercise 3–5 days/week', 1.55),
  active('Active', 'Exercise 6–7 days/week', 1.725),
  veryActive('Very active', 'Hard training / physical job', 1.9);

  const ActivityLevel(this.label, this.description, this.factor);

  final String label;
  final String description;
  final double factor;

  static ActivityLevel fromName(String? name) => ActivityLevel.values
      .firstWhere((a) => a.name == name, orElse: () => ActivityLevel.moderate);
}

/// Nutrition goal → how TDEE is adjusted for the calorie target.
enum Goal {
  lose('Lose weight', 0.8),
  maintain('Maintain', 1.0),
  gain('Gain muscle', 1.1);

  const Goal(this.label, this.calorieFactor);

  final String label;
  final double calorieFactor;

  static Goal fromName(String? name) =>
      Goal.values.firstWhere((g) => g.name == name, orElse: () => Goal.maintain);
}

/// The user's fixed/slow-changing profile used to compute health metrics.
/// Persisted as a single row (id = 1).
class Profile {
  const Profile({
    this.sex = Sex.male,
    this.birthYear,
    this.heightCm,
    this.activity = ActivityLevel.moderate,
    this.goal = Goal.maintain,
    this.targetWeight,
  });

  final Sex sex;
  final int? birthYear;
  final double? heightCm;
  final ActivityLevel activity;
  final Goal goal;
  final double? targetWeight;

  /// Age in years, or null if the birth year is unknown.
  int? age([DateTime? now]) {
    if (birthYear == null) return null;
    return (now ?? DateTime.now()).year - birthYear!;
  }

  bool get isComplete => birthYear != null && heightCm != null;

  Profile copyWith({
    Sex? sex,
    int? birthYear,
    double? heightCm,
    ActivityLevel? activity,
    Goal? goal,
    double? targetWeight,
    bool clearTargetWeight = false,
  }) {
    return Profile(
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      targetWeight:
          clearTargetWeight ? null : (targetWeight ?? this.targetWeight),
    );
  }

  Map<String, Object?> toMap() => {
        'id': 1,
        'sex': sex.name,
        'birth_year': birthYear,
        'height_cm': heightCm,
        'activity_level': activity.name,
        'goal': goal.name,
        'target_weight': targetWeight,
      };

  factory Profile.fromMap(Map<String, Object?> map) => Profile(
        sex: Sex.fromName(map['sex'] as String?),
        birthYear: map['birth_year'] as int?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        activity: ActivityLevel.fromName(map['activity_level'] as String?),
        goal: Goal.fromName(map['goal'] as String?),
        targetWeight: (map['target_weight'] as num?)?.toDouble(),
      );
}
