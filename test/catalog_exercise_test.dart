import 'package:flutter_test/flutter_test.dart';
import 'package:mygym/models/catalog_exercise.dart';

void main() {
  CatalogExercise fromEquip(String? equipment, {bool? bodyweight}) {
    final j = <String, dynamic>{
      'id': 'x',
      'name': 'X',
      'equipment': equipment,
    };
    if (bodyweight != null) j['bodyweight'] = bodyweight;
    return CatalogExercise.fromJson(j);
  }

  group('usesBodyweight', () {
    test('explicit true wins over a non-body-only equipment tag', () {
      // e.g. Dips - Chest Version, tagged "other" in the dataset.
      expect(fromEquip('other', bodyweight: true).usesBodyweight, isTrue);
    });

    test('explicit false wins over a body-only tag', () {
      expect(fromEquip('body only', bodyweight: false).usesBodyweight, isFalse);
    });

    test('falls back to equipment == "body only" when no flag', () {
      expect(fromEquip('body only').usesBodyweight, isTrue);
      expect(fromEquip('barbell').usesBodyweight, isFalse);
      expect(fromEquip(null).usesBodyweight, isFalse);
    });

    test('override patch can set the flag', () {
      final base = fromEquip('other');
      expect(base.usesBodyweight, isFalse);
      final patched = base.applyOverride({'bodyweight': true});
      expect(patched.usesBodyweight, isTrue);
    });
  });
}
