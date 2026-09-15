import '../models/exercise.dart';
import '../models/muscle_group.dart';
import 'exercise_media.dart';

/// Media (demo frames, muscles, instructions) for an exercise, or null.
ExerciseMedia? mediaFor(String exerciseName) => exerciseMedia[exerciseName];

/// The muscles highlighted for an exercise: uses the dataset when available,
/// otherwise falls back to a sensible set derived from its muscle group.
({Set<String> primary, Set<String> secondary}) musclesFor(Exercise exercise) {
  final media = mediaFor(exercise.name);
  if (media != null) {
    return (
      primary: media.primaryMuscles.toSet(),
      secondary: media.secondaryMuscles.toSet(),
    );
  }
  return (primary: _groupMuscles(exercise.group), secondary: <String>{});
}

Set<String> _groupMuscles(MuscleGroup group) {
  switch (group) {
    case MuscleGroup.chest:
      return {'chest'};
    case MuscleGroup.back:
      return {'lats', 'middle back', 'lower back', 'traps'};
    case MuscleGroup.legs:
      return {'quadriceps', 'hamstrings', 'glutes', 'calves'};
    case MuscleGroup.shoulders:
      return {'shoulders', 'traps'};
    case MuscleGroup.arms:
      return {'biceps', 'triceps', 'forearms'};
    case MuscleGroup.core:
      return {'abdominals'};
    case MuscleGroup.cardio:
      return {'quadriceps', 'hamstrings', 'calves', 'glutes'};
    case MuscleGroup.fullBody:
      return {'chest', 'lats', 'quadriceps', 'shoulders', 'glutes'};
    case MuscleGroup.other:
      return <String>{};
  }
}
