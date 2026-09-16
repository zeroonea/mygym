import 'package:flutter_test/flutter_test.dart';
import 'package:mygym/models/exercise_set.dart';
import 'package:mygym/models/profile.dart';
import 'package:mygym/utils/health.dart';

void main() {
  group('BMI', () {
    test('kg / m^2', () {
      expect(bmi(80, 180), closeTo(24.69, 0.01));
    });
    test('categories', () {
      expect(bmiCategory(17), BmiCategory.underweight);
      expect(bmiCategory(22), BmiCategory.normal);
      expect(bmiCategory(27), BmiCategory.overweight);
      expect(bmiCategory(32), BmiCategory.obese);
    });
  });

  group('BMR (Mifflin-St Jeor)', () {
    test('male', () {
      expect(bmr(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30),
          closeTo(1780, 0.5));
    });
    test('female', () {
      expect(bmr(sex: Sex.female, weightKg: 65, heightCm: 165, age: 30),
          closeTo(1370.25, 0.5));
    });
  });

  test('TDEE = BMR x activity factor', () {
    expect(tdee(bmr: 1780, activity: ActivityLevel.moderate),
        closeTo(1780 * 1.55, 0.5));
  });

  group('Body fat (US Navy)', () {
    test('male estimate is plausible', () {
      final bf = bodyFatNavy(
          sex: Sex.male, heightCm: 180, neck: 40, waist: 85);
      expect(bf, isNotNull);
      expect(bf!, inInclusiveRange(8, 22));
    });
    test('returns null without required measurements', () {
      expect(bodyFatNavy(sex: Sex.male, heightCm: 180, waist: 85), isNull);
      expect(bodyFatNavy(sex: Sex.female, heightCm: 165, neck: 32, waist: 70),
          isNull); // missing hip
    });
  });

  test('suggested target weight uses BMI 22', () {
    expect(suggestedTargetWeight(180), closeTo(71.28, 0.05));
  });

  group('macro plan', () {
    test('protein 2 g/kg, calories rounded, carbs positive', () {
      final plan = macroPlan(tdee: 2759, weightKg: 80, goal: Goal.maintain);
      expect(plan.protein, closeTo(160, 0.01));
      expect(plan.calories % 10, 0);
      expect(plan.carbs, greaterThan(0));
      expect(plan.fat, greaterThan(0));
    });
    test('cut lowers calories below maintenance', () {
      final maintain = macroPlan(tdee: 2500, weightKg: 80, goal: Goal.maintain);
      final cut = macroPlan(tdee: 2500, weightKg: 80, goal: Goal.lose);
      expect(cut.calories, lessThan(maintain.calories));
    });
  });

  group('bodyweight sets', () {
    test('volume counts bodyweight plus added load', () {
      const pushup = ExerciseSet(
        workoutExerciseId: 1,
        setNumber: 1,
        weight: 0,
        reps: 10,
        bodyWeight: 80,
      );
      expect(pushup.effectiveWeight, 80);
      expect(pushup.volume, 800);
      expect(pushup.isBodyweight, isTrue);

      const weightedPullup = ExerciseSet(
        workoutExerciseId: 1,
        setNumber: 1,
        weight: 10,
        reps: 5,
        bodyWeight: 80,
      );
      expect(weightedPullup.volume, 450); // (80 + 10) * 5
    });

    test('non-bodyweight set is unchanged', () {
      const barbell = ExerciseSet(
        workoutExerciseId: 1,
        setNumber: 1,
        weight: 100,
        reps: 5,
      );
      expect(barbell.isBodyweight, isFalse);
      expect(barbell.volume, 500);
    });
  });
}
