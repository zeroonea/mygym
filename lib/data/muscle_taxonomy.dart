import '../models/muscle_group.dart';

/// Maps any muscle name — broad (`shoulders`) or precise (`lateral deltoid`) —
/// to the body-map region key used by the muscle map painter, or null if it
/// has no drawn region.
String? baseRegion(String muscle) {
  final m = muscle.toLowerCase();
  bool has(String s) => m.contains(s);

  if (has('delt') || has('shoulder')) return 'shoulders';
  if (has('chest') || has('pec')) return 'chest';
  if (has('tricep')) return 'triceps';
  if (has('bicep') || has('brachialis')) return 'biceps';
  if (has('forearm') || has('brachioradialis') || has('wrist')) {
    return 'forearms';
  }
  if (has('quad') ||
      has('hip flexor') ||
      has('rectus femoris') ||
      has('vastus')) {
    return 'quadriceps';
  }
  if (has('hamstring')) return 'hamstrings';
  if (has('glute')) return 'glutes';
  if (has('calf') || has('calves') || has('gastro') || has('soleus')) {
    return 'calves';
  }
  if (has('lat')) return 'lats';
  if (has('trap')) return 'traps';
  if (has('rhomboid') || has('middle back') || has('upper back')) {
    return 'middle back';
  }
  if (has('lower back') || has('erector') || has('spinal')) {
    return 'lower back';
  }
  if (has('oblique')) return 'obliques';
  if (has('abdominal') ||
      has('abs') ||
      has('core') ||
      has('transverse')) {
    return 'abdominals';
  }
  if (has('adductor') || has('inner thigh')) return 'adductors';
  if (has('abductor') || has('outer thigh')) return 'abductors';
  if (has('neck') || has('sternocleido')) return 'neck';
  return null;
}

/// The broad [MuscleGroup] an individual muscle belongs to.
MuscleGroup groupForMuscle(String muscle) {
  switch (baseRegion(muscle)) {
    case 'chest':
      return MuscleGroup.chest;
    case 'lats':
    case 'middle back':
    case 'lower back':
    case 'traps':
      return MuscleGroup.back;
    case 'shoulders':
      return MuscleGroup.shoulders;
    case 'biceps':
    case 'triceps':
    case 'forearms':
      return MuscleGroup.arms;
    case 'quadriceps':
    case 'hamstrings':
    case 'glutes':
    case 'calves':
    case 'adductors':
    case 'abductors':
      return MuscleGroup.legs;
    case 'abdominals':
    case 'obliques':
    case 'neck':
      return MuscleGroup.core;
  }
  return MuscleGroup.other;
}

/// Title-cases a muscle name for display (e.g. `lateral deltoid` -> `Lateral
/// Deltoid`).
String prettyMuscle(String muscle) => muscle
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
