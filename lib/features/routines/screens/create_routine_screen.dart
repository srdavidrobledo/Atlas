import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/exercise_catalog.dart';
import '../../../shared/mock_data.dart';
import '../data/routine_store.dart';

class _DayDraft {
  String name;
  final List<ExerciseCatalogEntry> exercises;
  _DayDraft({required this.name}) : exercises = [];
}

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final List<_DayDraft> _days = [];
  final List<TextEditingController> _dayControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _dayControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    final index = _days.length + 1;
    setState(() {
      _days.add(_DayDraft(name: 'Día $index'));
      _dayControllers.add(TextEditingController(text: 'Día $index'));
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
      _dayControllers[index].dispose();
      _dayControllers.removeAt(index);
    });
  }

  void _addExercises(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExercisePickerSheet(
        alreadyAdded: _days[dayIndex].exercises.map((e) => e.id).toSet(),
        onConfirm: (entries) {
          setState(() => _days[dayIndex].exercises.addAll(entries));
        },
      ),
    );
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() => _days[dayIndex].exercises.removeAt(exIndex));
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _days.isNotEmpty;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _days.isEmpty) return;

    final routine = RoutineStore.createRoutine(name);

    for (var i = 0; i < _days.length; i++) {
      final draft = _days[i];
      final dayName = _dayControllers[i].text.trim().isNotEmpty
          ? _dayControllers[i].text.trim()
          : draft.name;

      final exercises = draft.exercises.map((e) {
        return MockExercise(
          name: e.name,
          muscle: '${e.muscleGroup} · ${e.equipment}',
          sets: List.generate(
            e.defaultSets,
            (_) => MockSet(kg: 0, reps: e.defaultReps, rir: null, done: false),
          ),
          prevKg: 0,
          prevReps: e.defaultReps,
        );
      }).toList();

      routine.days.add(
        MockRoutineDay(
          id: 'day_${routine.id}_$i',
          name: dayName,
          exercises: exercises,
        ),
      );
    }
    await RoutineStore.persistRoutines();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rutina "$name" creada'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.pop(true); // devuelve true para que RoutinesScreen sepa que hubo cambios
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNameSection(),
                  const SizedBox(height: 20),
                  ..._buildDayList(),
                  const SizedBox(height: 8),
                  _buildAddDayButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1C0E2E),
        border: Border(bottom: BorderSide(color: Color(0xFF3D2260), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Nueva rutina', style: AppTextStyles.titleMedium),
          ),
          ValueListenableBuilder(
            valueListenable: _nameController,
            builder: (_, __, ___) => TextButton(
              onPressed: _canSave ? _save : null,
              child: Text(
                'Guardar',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _canSave
                      ? AppColors.primaryLight
                      : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOMBRE DE LA RUTINA',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ej: Push Pull Legs',
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3F3F46), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3F3F46), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D2260), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDayList() {
    if (_days.isEmpty) return [];
    return [
      Text(
        'DÍAS',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: 8),
      ...List.generate(_days.length, _buildDayCard),
    ];
  }

  Widget _buildDayCard(int index) {
    final day = _days[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dayControllers[index],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeDay(index),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'Sin ejercicios',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
              ),
            )
          else
            ...List.generate(day.exercises.length, (ei) {
              final ex = day.exercises[ei];
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.name,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            '${ex.muscleGroup} · ${ex.defaultSets} series × ${ex.defaultReps} reps',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeExercise(index, ei),
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 16,
                        color: AppColors.textDisabled,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: OutlinedButton.icon(
              onPressed: () => _addExercises(index),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar ejercicio'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                side: const BorderSide(color: Color(0xFF3F3F46), width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDayButton() {
    return OutlinedButton.icon(
      onPressed: _addDay,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Agregar día'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
        side: const BorderSide(color: Color(0xFF3D2260), width: 0.8),
        foregroundColor: AppColors.primaryLight,
      ),
    );
  }
}

// ─── Picker multi-selección ────────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  final Set<String> alreadyAdded;
  final ValueChanged<List<ExerciseCatalogEntry>> onConfirm;

  const _ExercisePickerSheet({
    required this.alreadyAdded,
    required this.onConfirm,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';
  String? _filterGroup;

  // Selección pendiente en esta sesión del picker
  final Set<String> _pending = {};

  // Normaliza texto para comparación sin importar tildes ni capitalización
  static String _n(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  List<ExerciseCatalogEntry> get _filtered {
    final q = _n(_query);
    return ExerciseCatalog.all.where((e) {
      final matchesGroup =
          _filterGroup == null || e.muscleGroup == _filterGroup;
      final matchesQuery = q.isEmpty ||
          _n(e.name).contains(q) ||
          _n(e.muscleGroup).contains(q);
      return matchesGroup && matchesQuery;
    }).toList();
  }

  List<ExerciseCatalogEntry> get _filteredSelectable =>
      _filtered.where((e) => !widget.alreadyAdded.contains(e.id)).toList();

  bool get _allFilteredSelected =>
      _filteredSelectable.isNotEmpty &&
      _filteredSelectable.every((e) => _pending.contains(e.id));

  void _toggleEntry(ExerciseCatalogEntry e) {
    setState(() {
      if (_pending.contains(e.id)) {
        _pending.remove(e.id);
      } else {
        _pending.add(e.id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allFilteredSelected) {
        for (final e in _filteredSelectable) {
          _pending.remove(e.id);
        }
      } else {
        for (final e in _filteredSelectable) {
          _pending.add(e.id);
        }
      }
    });
  }

  void _confirm() {
    final entries = ExerciseCatalog.all
        .where((e) => _pending.contains(e.id))
        .toList();
    widget.onConfirm(entries);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectable = _filteredSelectable;
    final pendingCount = _pending.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // ── Cabecera ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agregar ejercicios',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingCount seleccionado${pendingCount == 1 ? '' : 's'}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Búsqueda
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o músculo...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDisabled),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF3F3F46), width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF3F3F46), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF3D2260), width: 1),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                // Filtros por grupo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Todos', null),
                      ...ExerciseCatalog.muscleGroups
                          .map((g) => _filterChip(g, g)),
                    ],
                  ),
                ),
                // Seleccionar todos (visible cuando hay selectable en el filtro)
                if (selectable.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _toggleSelectAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _allFilteredSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: _allFilteredSelected
                                ? AppColors.primaryLight
                                : AppColors.textDisabled,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _allFilteredSelected
                                ? 'Deseleccionar todos'
                                : 'Seleccionar todos'
                                    '${_filterGroup != null ? ' ($_filterGroup)' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _allFilteredSelected
                                  ? AppColors.primaryLight
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          // ── Lista ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Sin resultados para "$_query"',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textDisabled),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final entry = filtered[i];
                      final isAlreadyAdded =
                          widget.alreadyAdded.contains(entry.id);
                      final isPending = _pending.contains(entry.id);

                      return ListTile(
                        dense: true,
                        enabled: !isAlreadyAdded,
                        onTap:
                            isAlreadyAdded ? null : () => _toggleEntry(entry),
                        leading: isAlreadyAdded
                            ? const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.textDisabled,
                              )
                            : isPending
                                ? const Icon(
                                    Icons.check_box_rounded,
                                    size: 18,
                                    color: AppColors.primaryLight,
                                  )
                                : const Icon(
                                    Icons.check_box_outline_blank_rounded,
                                    size: 18,
                                    color: AppColors.textDisabled,
                                  ),
                        title: Text(
                          entry.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isAlreadyAdded
                                ? AppColors.textDisabled
                                : isPending
                                    ? AppColors.primaryLight
                                    : AppColors.textPrimary,
                            fontWeight: isPending
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          '${entry.muscleGroup} · ${entry.equipment}'
                          ' · ${entry.defaultSets}×${entry.defaultReps}',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                        tileColor: isPending
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : null,
                      );
                    },
                  ),
          ),
          // ── Botón confirmar ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
            child: FilledButton(
              onPressed: pendingCount > 0 ? _confirm : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                pendingCount == 0
                    ? 'Selecciona ejercicios'
                    : 'Agregar $pendingCount ejercicio${pendingCount == 1 ? '' : 's'}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: pendingCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? group) {
    final isSelected = _filterGroup == group;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => setState(() => _filterGroup = group),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 11,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        side: BorderSide(
          color:
              isSelected ? AppColors.primaryLight : const Color(0xFF3F3F46),
          width: isSelected ? 1.0 : 0.5,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
