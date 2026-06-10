import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/meal_entry.dart';
import '../data/nutrition_store.dart';
import 'log_meal_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDay = DateTime.now();

  List<MealEntry> get _meals => NutritionStore.mealsForDay(_selectedDay);
  int    get _calories => NutritionStore.caloriesForDay(_selectedDay);
  double get _protein  => NutritionStore.proteinForDay(_selectedDay);

  Future<void> _openLogMeal() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LogMealScreen()),
    );
    if (added == true) setState(() {});
  }

  Future<void> _deleteMeal(String id) async {
    await NutritionStore.removeMeal(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Nutrición', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(
              () => _selectedDay =
                  _selectedDay.subtract(const Duration(days: 1)),
            ),
          ),
          Center(
            child: Text(_dayLabel(_selectedDay),
                style: AppTextStyles.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _isToday
                ? null
                : () => setState(
                      () => _selectedDay =
                          _selectedDay.add(const Duration(days: 1)),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 8),
          Expanded(child: _buildMealList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLogMeal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Agregar comida', style: AppTextStyles.labelSmall),
      ),
    );
  }

  // ── Resumen del día ────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Row(
        children: [
          _StatBlock(
            value: '$_calories',
            label: 'kcal',
            color: AppColors.primary,
          ),
          const SizedBox(width: 32),
          _StatBlock(
            value: '${_protein.toStringAsFixed(1)}g',
            label: 'proteínas',
            color: AppColors.secondary,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_meals.length}',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.textPrimary)),
              Text('comidas',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  // ── Lista de comidas ───────────────────────────────────────────────────────

  Widget _buildMealList() {
    if (_meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Sin comidas registradas',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text('Toca el botón para agregar una comida',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final grouped = _groupByType(_meals);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(entry.key.label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            ...entry.value.map(_buildMealTile),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMealTile(MealEntry meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(meal.name,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w500)),
        subtitle: meal.notes != null
            ? Text(meal.notes!, style: AppTextStyles.bodySmall)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${meal.calories} kcal',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600)),
                if (meal.protein > 0)
                  Text('${meal.protein.toStringAsFixed(1)}g prot',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: () => _deleteMeal(meal.id),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoy';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Ayer';
    }
    return '${d.day}/${d.month}';
  }

  Map<MealType, List<MealEntry>> _groupByType(List<MealEntry> meals) {
    final order = MealType.values;
    final map = <MealType, List<MealEntry>>{};
    for (final type in order) {
      final group = meals.where((m) => m.mealType == type).toList();
      if (group.isNotEmpty) map[type] = group;
    }
    return map;
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBlock({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.titleLarge.copyWith(color: color)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
