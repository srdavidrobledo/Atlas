import 'dart:convert';
import '../../../core/storage/atlas_storage.dart';
import 'meal_entry.dart';

class NutritionStore {
  static final List<MealEntry> _meals = [];

  static List<MealEntry> get meals => List.unmodifiable(_meals);

  static Future<void> init() async {
    final raw = AtlasStorage.nutrition.get('meals') as String?;
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _meals.addAll(
        list.map((e) => MealEntry.fromJson(Map<String, dynamic>.from(e as Map))),
      );
    }
  }

  // ── Mutaciones ────────────────────────────────────────────────────────────

  static Future<void> addMeal(MealEntry entry) async {
    _meals.insert(0, entry);
    await persistMeals();
  }

  static Future<void> removeMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
    await persistMeals();
  }

  static Future<void> updateMeal(MealEntry updated) async {
    final index = _meals.indexWhere((m) => m.id == updated.id);
    if (index == -1) return;
    _meals[index] = updated;
    await persistMeals();
  }

  static Future<void> persistMeals() async {
    await AtlasStorage.nutrition.put(
      'meals',
      jsonEncode(_meals.map((m) => m.toJson()).toList()),
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  static List<MealEntry> mealsForDay(DateTime day) {
    return _meals.where((m) => _sameDay(m.date, day)).toList();
  }

  static int caloriesForDay(DateTime day) {
    return mealsForDay(day).fold(0, (sum, m) => sum + m.calories);
  }

  static double proteinForDay(DateTime day) {
    return mealsForDay(day).fold(0.0, (sum, m) => sum + m.protein);
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String newId() => 'meal_${DateTime.now().millisecondsSinceEpoch}';
}
