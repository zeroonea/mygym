/// One dated body-measurement log entry. Weight is required; everything else is
/// optional. Circumferences are in centimetres, weight in kilograms.
class BodyEntry {
  const BodyEntry({
    this.id,
    required this.date,
    required this.weight,
    this.bodyFat,
    this.neck,
    this.chest,
    this.waist,
    this.hip,
    this.arm,
    this.thigh,
    this.calf,
    this.notes,
  });

  final int? id;
  final DateTime date;
  final double weight;
  final double? bodyFat;
  final double? neck;
  final double? chest;
  final double? waist;
  final double? hip;
  final double? arm;
  final double? thigh;
  final double? calf;
  final String? notes;

  BodyEntry copyWith({
    int? id,
    DateTime? date,
    double? weight,
    double? bodyFat,
    double? neck,
    double? chest,
    double? waist,
    double? hip,
    double? arm,
    double? thigh,
    double? calf,
    String? notes,
  }) {
    return BodyEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      neck: neck ?? this.neck,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      arm: arm ?? this.arm,
      thigh: thigh ?? this.thigh,
      calf: calf ?? this.calf,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.millisecondsSinceEpoch,
        'weight': weight,
        'body_fat': bodyFat,
        'neck': neck,
        'chest': chest,
        'waist': waist,
        'hip': hip,
        'arm': arm,
        'thigh': thigh,
        'calf': calf,
        'notes': notes,
      };

  factory BodyEntry.fromMap(Map<String, Object?> map) => BodyEntry(
        id: map['id'] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        weight: (map['weight'] as num).toDouble(),
        bodyFat: (map['body_fat'] as num?)?.toDouble(),
        neck: (map['neck'] as num?)?.toDouble(),
        chest: (map['chest'] as num?)?.toDouble(),
        waist: (map['waist'] as num?)?.toDouble(),
        hip: (map['hip'] as num?)?.toDouble(),
        arm: (map['arm'] as num?)?.toDouble(),
        thigh: (map['thigh'] as num?)?.toDouble(),
        calf: (map['calf'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
      );
}
