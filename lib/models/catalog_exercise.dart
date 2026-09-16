import '../data/muscle_taxonomy.dart';
import '../data/remote_config.dart';
import 'muscle_group.dart';

/// A library exercise, sourced from the bundled dataset (and optionally
/// enriched by the remote overrides file), or created by the user.
class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    this.category,
    this.equipment,
    this.level,
    this.force,
    this.mechanic,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.imageUrls = const [],
    this.notes,
    this.isCustom = false,
    this.groupOverride,
    this.bodyweight,
  });

  final String id;
  final String name;
  final String? category;
  final String? equipment;
  final String? level;
  final String? force;
  final String? mechanic;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<String> imageUrls;
  final String? notes;
  final bool isCustom;

  /// When set, forces the broad group (used by custom exercises and history
  /// snapshots) instead of deriving it from muscles.
  final MuscleGroup? groupOverride;

  /// Explicit "is this a bodyweight-loaded movement?" flag from the dataset.
  /// Curated per-exercise (the raw `equipment` tag is unreliable — e.g. dips
  /// and muscle-ups are tagged `other`), so when present it wins over the
  /// equipment heuristic in [usesBodyweight].
  final bool? bodyweight;

  /// Broad muscle group, for icon/colour and grouping.
  MuscleGroup get group {
    if (groupOverride != null) return groupOverride!;
    if (category == 'cardio') return MuscleGroup.cardio;
    if (primaryMuscles.isNotEmpty) return groupForMuscle(primaryMuscles.first);
    return MuscleGroup.other;
  }

  bool get hasDemo => imageUrls.isNotEmpty;

  /// Whether the exercise is primarily loaded by the lifter's own bodyweight
  /// (push-up, pull-up, dip …). Volume then counts bodyweight toward the load.
  ///
  /// Prefers the curated [bodyweight] flag; falls back to the dataset's
  /// `equipment == 'body only'` tag when no flag is set (e.g. custom exercises).
  bool get usesBodyweight =>
      bodyweight ?? (equipment ?? '').toLowerCase() == 'body only';

  static List<String> _strings(Object? v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  static List<String> _images(Object? v) => _strings(v)
      .map((p) => p.startsWith('http') ? p : '${RemoteConfig.imageBase}$p')
      .toList();

  factory CatalogExercise.fromJson(Map<String, dynamic> j,
      {bool isCustom = false}) {
    return CatalogExercise(
      id: j['id'].toString(),
      name: j['name'].toString(),
      category: j['category']?.toString(),
      equipment: j['equipment']?.toString(),
      level: j['level']?.toString(),
      force: j['force']?.toString(),
      mechanic: j['mechanic']?.toString(),
      primaryMuscles: _strings(j['primaryMuscles']),
      secondaryMuscles: _strings(j['secondaryMuscles']),
      instructions: _strings(j['instructions']),
      imageUrls: _images(j['images']),
      notes: j['notes']?.toString(),
      isCustom: isCustom || j['isCustom'] == true,
      bodyweight: j['bodyweight'] is bool ? j['bodyweight'] as bool : null,
    );
  }

  /// Applies an override patch (only the keys present are changed).
  CatalogExercise applyOverride(Map<String, dynamic> ov) {
    return CatalogExercise(
      id: id,
      name: ov['name']?.toString() ?? name,
      category: ov['category']?.toString() ?? category,
      equipment: ov['equipment']?.toString() ?? equipment,
      level: ov['level']?.toString() ?? level,
      force: force,
      mechanic: mechanic,
      primaryMuscles: ov.containsKey('primaryMuscles')
          ? _strings(ov['primaryMuscles'])
          : primaryMuscles,
      secondaryMuscles: ov.containsKey('secondaryMuscles')
          ? _strings(ov['secondaryMuscles'])
          : secondaryMuscles,
      instructions: ov.containsKey('instructions')
          ? _strings(ov['instructions'])
          : instructions,
      imageUrls: ov.containsKey('images') ? _images(ov['images']) : imageUrls,
      notes: ov['notes']?.toString() ?? notes,
      isCustom: isCustom,
      bodyweight: ov['bodyweight'] is bool ? ov['bodyweight'] as bool : bodyweight,
    );
  }

  /// A minimal placeholder built from a workout's stored snapshot, used when a
  /// logged exercise id is no longer in the catalog.
  factory CatalogExercise.placeholder({
    required String id,
    required String name,
    MuscleGroup? group,
  }) {
    return CatalogExercise(id: id, name: name, groupOverride: group);
  }
}
