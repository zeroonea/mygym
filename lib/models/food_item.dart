/// A food and its macronutrients, normalised to per-100g values (kcal + grams).
/// Some foods also carry a suggested serving size in grams.
class FoodItem {
  const FoodItem({
    required this.name,
    this.brand,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingGrams,
  });

  final String name;
  final String? brand;
  final double kcal; // per 100 g
  final double protein; // per 100 g
  final double carbs; // per 100 g
  final double fat; // per 100 g
  final double? servingGrams;

  /// Macros scaled to [grams].
  ({double kcal, double protein, double carbs, double fat}) per(double grams) {
    final f = grams / 100.0;
    return (
      kcal: kcal * f,
      protein: protein * f,
      carbs: carbs * f,
      fat: fat * f,
    );
  }

  /// Parses an Open Food Facts product record. Returns null if it lacks a name
  /// or has no usable energy value.
  static FoodItem? fromOpenFoodFacts(Map<String, dynamic> j) {
    final name = (j['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    final n = (j['nutriments'] as Map?)?.cast<String, dynamic>() ?? const {};

    double num0(Object? v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

    final kcal = num0(n['energy-kcal_100g']);
    final protein = num0(n['proteins_100g']);
    final carbs = num0(n['carbohydrates_100g']);
    final fat = num0(n['fat_100g']);
    if (kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) return null;

    final brand = (j['brands'] as String?)?.split(',').first.trim();
    double? serving;
    final sq = j['serving_quantity'];
    if (sq is num) {
      serving = sq.toDouble();
    } else if (sq is String) {
      serving = double.tryParse(sq);
    }

    return FoodItem(
      name: name,
      brand: brand == null || brand.isEmpty ? null : brand,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servingGrams: (serving != null && serving > 0) ? serving : null,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> j) {
    double num0(Object? v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    return FoodItem(
      name: j['name'].toString(),
      brand: j['brand']?.toString(),
      kcal: num0(j['kcal']),
      protein: num0(j['protein']),
      carbs: num0(j['carbs']),
      fat: num0(j['fat']),
      servingGrams: (j['servingGrams'] as num?)?.toDouble(),
    );
  }
}
