enum MealType { breakfast, lunch, snack, dinner, extra }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Desayuno',
        MealType.lunch     => 'Almuerzo',
        MealType.snack     => 'Merienda',
        MealType.dinner    => 'Cena',
        MealType.extra     => 'Snack',
      };
}

class MealEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final DateTime date;
  final MealType mealType;
  final String? notes;

  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.date,
    required this.mealType,
    this.notes,
  });

  MealEntry copyWith({
    String? name,
    int? calories,
    double? protein,
    DateTime? date,
    MealType? mealType,
    String? notes,
  }) =>
      MealEntry(
        id: id,
        name: name ?? this.name,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'date': date.toIso8601String(),
        'mealType': mealType.name,
        'notes': notes,
      };

  factory MealEntry.fromJson(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as String,
        name: m['name'] as String,
        calories: m['calories'] as int,
        protein: (m['protein'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
        mealType: MealType.values.byName(m['mealType'] as String),
        notes: m['notes'] as String?,
      );
}
