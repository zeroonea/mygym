import 'dart:math' as math;

import '../models/body_entry.dart';
import '../models/profile.dart';

/// A weight class derived from BMI.
enum BmiCategory {
  underweight('Underweight'),
  normal('Normal'),
  overweight('Overweight'),
  obese('Obese');

  const BmiCategory(this.label);
  final String label;
}

/// Recommended daily macronutrient split, in grams, plus the calorie target.
class MacroPlan {
  const MacroPlan({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
}

/// Health metrics computed from a [Profile] and a body-measurement entry.
/// Any field is null when its inputs are missing.
class HealthStats {
  const HealthStats({
    this.bmi,
    this.bmiCategory,
    this.bmr,
    this.tdee,
    this.bodyFatPercent,
    this.leanMass,
    this.macros,
  });

  final double? bmi;
  final BmiCategory? bmiCategory;
  final double? bmr;
  final double? tdee;
  final double? bodyFatPercent;
  final double? leanMass;
  final MacroPlan? macros;

  /// Computes all metrics from a [Profile] and the most recent body entry.
  static HealthStats compute({
    required Profile profile,
    required BodyEntry? latest,
  }) =>
      computeHealthStats(profile: profile, latest: latest);
}

/// Builds a [HealthStats] from a profile and its latest measurement entry.
///
/// Kept as a top-level function (not a method) so the bare `bmi`, `bmr`,
/// `tdee` and `bmiCategory` calls resolve to the functions below rather than
/// [HealthStats]'s identically-named fields.
HealthStats computeHealthStats({
  required Profile profile,
  required BodyEntry? latest,
}) {
  final weight = latest?.weight;
  final height = profile.heightCm;
  final age = profile.age();

  final bmiValue =
      (weight != null && height != null) ? bmi(weight, height) : null;

  final bmrValue = (weight != null && height != null && age != null)
      ? bmr(sex: profile.sex, weightKg: weight, heightCm: height, age: age)
      : null;

  final tdeeValue =
      bmrValue != null ? bmrValue * profile.activity.factor : null;

  // Prefer a directly measured body-fat %, else estimate from tape (Navy).
  double? bf = latest?.bodyFat;
  if (bf == null && latest != null && height != null) {
    bf = bodyFatNavy(
      sex: profile.sex,
      heightCm: height,
      neck: latest.neck,
      waist: latest.waist,
      hip: latest.hip,
    );
  }

  final lean = (weight != null && bf != null) ? weight * (1 - bf / 100) : null;

  MacroPlan? plan;
  if (tdeeValue != null && weight != null) {
    plan = macroPlan(tdee: tdeeValue, weightKg: weight, goal: profile.goal);
  }

  return HealthStats(
    bmi: bmiValue,
    bmiCategory: bmiValue == null ? null : bmiCategory(bmiValue),
    bmr: bmrValue,
    tdee: tdeeValue,
    bodyFatPercent: bf,
    leanMass: lean,
    macros: plan,
  );
}

/// Body Mass Index: kg / m².
double bmi(double weightKg, double heightCm) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

BmiCategory bmiCategory(double bmi) {
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}

/// Basal Metabolic Rate via the Mifflin-St Jeor equation (kcal/day).
double bmr({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex == Sex.male ? base + 5 : base - 161;
}

/// Total Daily Energy Expenditure = BMR × activity factor (kcal/day).
double tdee({required double bmr, required ActivityLevel activity}) =>
    bmr * activity.factor;

/// US-Navy body-fat estimate (%). Needs neck + waist (+ hip for women).
/// Returns null if the required measurements are missing.
double? bodyFatNavy({
  required Sex sex,
  required double heightCm,
  double? neck,
  double? waist,
  double? hip,
}) {
  if (neck == null || waist == null || neck <= 0 || waist <= 0) return null;
  double log10(double x) => math.log(x) / math.ln10;
  if (sex == Sex.male) {
    if (waist - neck <= 0) return null;
    final v = 495 /
            (1.0324 -
                0.19077 * log10(waist - neck) +
                0.15456 * log10(heightCm)) -
        450;
    return v.isFinite && v > 0 ? v : null;
  } else {
    if (hip == null || hip <= 0) return null;
    if (waist + hip - neck <= 0) return null;
    final v = 495 /
            (1.29579 -
                0.35004 * log10(waist + hip - neck) +
                0.22100 * log10(heightCm)) -
        450;
    return v.isFinite && v > 0 ? v : null;
  }
}

/// Weight (kg) at the midpoint of the healthy BMI range (BMI 22) for a height.
double suggestedTargetWeight(double heightCm) {
  final m = heightCm / 100;
  return 22 * m * m;
}

/// The healthy weight range (BMI 18.5–24.9) for a height, in kg.
({double min, double max}) healthyWeightRange(double heightCm) {
  final m = heightCm / 100;
  return (min: 18.5 * m * m, max: 24.9 * m * m);
}

/// A macro split for the calorie target implied by the goal.
///
/// Protein is fixed at 2.0 g/kg, fat at 25% of calories, carbs fill the rest.
MacroPlan macroPlan({
  required double tdee,
  required double weightKg,
  required Goal goal,
}) {
  final calories = (tdee * goal.calorieFactor / 10).round() * 10.0;
  final protein = 2.0 * weightKg;
  final fat = calories * 0.25 / 9;
  final proteinCals = protein * 4;
  final fatCals = fat * 9;
  final carbs = math.max(0, (calories - proteinCals - fatCals) / 4).toDouble();
  return MacroPlan(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}
