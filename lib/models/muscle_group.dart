import 'package:flutter/material.dart';

/// The muscle group / category an exercise targets.
///
/// Stored in the database by its [name] (e.g. `chest`). Carries display
/// metadata (label, icon, colour) so the UI stays consistent everywhere.
enum MuscleGroup {
  chest('Chest', Icons.fitness_center, Color(0xFFEF4444)),
  back('Back', Icons.rowing, Color(0xFF3B82F6)),
  legs('Legs', Icons.directions_walk, Color(0xFF22C55E)),
  shoulders('Shoulders', Icons.accessibility_new, Color(0xFFF59E0B)),
  arms('Arms', Icons.sports_gymnastics, Color(0xFF8B5CF6)),
  core('Core', Icons.self_improvement, Color(0xFFEC4899)),
  cardio('Cardio', Icons.directions_run, Color(0xFF06B6D4)),
  fullBody('Full Body', Icons.sports_martial_arts, Color(0xFF14B8A6)),
  other('Other', Icons.category, Color(0xFF64748B));

  const MuscleGroup(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Resolve a stored name back to a [MuscleGroup], defaulting to [other].
  static MuscleGroup fromName(String? name) => MuscleGroup.values.firstWhere(
        (e) => e.name == name,
        orElse: () => MuscleGroup.other,
      );
}
