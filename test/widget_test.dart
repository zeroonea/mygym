import 'package:flutter_test/flutter_test.dart';
import 'package:mygym/models/exercise_set.dart';
import 'package:mygym/utils/format.dart';

void main() {
  group('formatWeight', () {
    test('drops trailing .0', () {
      expect(formatWeight(60), '60');
      expect(formatWeight(62.5), '62.5');
    });
  });

  group('ExerciseSet', () {
    const set = ExerciseSet(
      workoutExerciseId: 1,
      setNumber: 1,
      weight: 100,
      reps: 5,
    );

    test('volume is weight times reps', () {
      expect(set.volume, 500);
    });

    test('estimated 1RM uses Epley formula', () {
      // 100 * (1 + 5/30) = 116.67
      expect(set.estimatedOneRepMax, closeTo(116.67, 0.01));
    });

    test('single rep 1RM equals the weight', () {
      const single = ExerciseSet(
        workoutExerciseId: 1,
        setNumber: 1,
        weight: 120,
        reps: 1,
      );
      expect(single.estimatedOneRepMax, 120);
    });
  });
}
