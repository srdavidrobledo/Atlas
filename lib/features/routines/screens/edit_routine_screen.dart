import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/exercise_catalog.dart';
import '../../../shared/mock_data.dart';
import '../data/routine_store.dart';

class EditRoutineScreen extends StatefulWidget {
  final String routineId;
  const EditRoutineScreen({super.key, required this.routineId});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  late MockRoutine _routine;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _routine = RoutineStore.all.firstWhere((r) => r.id == widget.routineId);
    _nameCtrl = TextEditingController(text: _routine.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {
        _routine = RoutineStore.all.firstWhere((r) => r.id == widget.routineId);
      });

  // ── Rutina ────────────────────────────────────────────────────────────────

  Future<void> _saveRoutineName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == _routine.name) return;
    await RoutineStore.renameRoutine(widget.routineId, name);
    _refresh();
  }

  Future<void> _duplicateRoutine() async {
    await RoutineStore.duplicateRoutine(widget.routineId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rutina duplicada'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar rutina', style: AppTextStyles.titleMedium),
        content: Text(
          '¿Eliminar "${_routine.name}"? Esta acción no se puede deshacer.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await RoutineStore.deleteRoutine(widget.routineId);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('StateError: ', '')),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Días ──────────────────────────────────────────────────────────────────

  Future<void> _addDay() async {
    final ctrl = TextEditingController(text: 'Día ${_routine.days.length + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Nuevo día',
        controller: ctrl,
        hint: 'Ej: Push, Piernas…',
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await RoutineStore.addDay(widget.routineId, name.trim());
    _refresh();
  }

  Future<void> _renameDay(MockRoutineDay day) async {
    final ctrl = TextEditingController(text: day.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Renombrar día',
        controller: ctrl,
        hint: 'Nombre del día',
      ),
    );
    if (name == null || name.trim().isEmpty || name.trim() == day.name) return;
    await RoutineStore.renameDay(widget.routineId, day.id, name.trim());
    _refresh();
  }

  Future<void> _deleteDay(MockRoutineDay day) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar día', style: AppTextStyles.titleMedium),
        content: Text('¿Eliminar "${day.name}"?', style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await RoutineStore.removeDay(widget.routineId, day.id);
    _refresh();
  }

  // ── Ejercicios ────────────────────────────────────────────────────────────

  void _openExercisePicker(MockRoutineDay day) {
    final already = day.exercises.map((e) => e.name).toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExercisePickerSheet(
        alreadyAdded: already,
        onConfirm: (entries) async {
          for (final e in entries) {
            final ex = MockExercise(
              name: e.name,
              muscle: '${e.muscleGroup} · ${e.equipment}',
              sets: List.generate(
                e.defaultSets,
                (_) => MockSet(kg: 0, reps: e.defaultReps, rir: null, done: false),
              ),
              prevKg: 0,
              prevReps: e.defaultReps,
            );
            await RoutineStore.addExercise(widget.routineId, day.id, ex);
          }
          _refresh();
        },
      ),
    );
  }

  Future<void> _editSetsReps(MockRoutineDay day, int exIndex) async {
    final ex = day.exercises[exIndex];
    final setsCtrl = TextEditingController(text: '${ex.sets.length}');
    final repsCtrl = TextEditingController(
        text: '${ex.sets.isNotEmpty ? ex.sets.first.reps : 10}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ex.name, style: AppTextStyles.titleMedium),
        content: Row(
          children: [
            Expanded(
              child: _NumField(controller: setsCtrl, label: 'Series'),
            ),
            const SizedBox(width: 12),
            const Text('×', style: TextStyle(fontSize: 20, color: Colors.white70)),
            const SizedBox(width: 12),
            Expanded(
              child: _NumField(controller: repsCtrl, label: 'Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final sets = int.tryParse(setsCtrl.text.trim()) ?? ex.sets.length;
    final reps = int.tryParse(repsCtrl.text.trim()) ??
        (ex.sets.isNotEmpty ? ex.sets.first.reps : 10);

    final updated = MockExercise(
      name: ex.name,
      muscle: ex.muscle,
      sets: List.generate(
          sets, (_) => MockSet(kg: 0, reps: reps, rir: null, done: false)),
      prevKg: ex.prevKg,
      prevReps: reps,
    );
    await RoutineStore.updateExercise(widget.routineId, day.id, exIndex, updated);
    _refresh();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(true),
        ),
        title: _RoutineNameField(
          controller: _nameCtrl,
          onSubmitted: (_) => _saveRoutineName(),
        ),
        actions: [
          PopupMenuButton<String>(
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'duplicate') _duplicateRoutine();
              if (v == 'delete') _deleteRoutine();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'duplicate',
                child: Row(children: [
                  const Icon(Icons.copy_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text('Duplicar rutina', style: AppTextStyles.bodySmall),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text('Eliminar rutina',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: _routine.days.isEmpty
          ? _buildEmptyState()
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              onReorderItem: (oldIndex, newIndex) async {
                await RoutineStore.reorderDay(
                    widget.routineId, oldIndex, newIndex);
                _refresh();
              },
              itemCount: _routine.days.length,
              itemBuilder: (_, i) {
                final day = _routine.days[i];
                return _buildDayCard(day, i);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDay,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar día'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Sin días', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('Toca el botón para agregar un día',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDayCard(MockRoutineDay day, int dayIndex) {
    return Container(
      key: ValueKey(day.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera del día ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: dayIndex,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.drag_handle_rounded,
                        size: 20, color: AppColors.textDisabled),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _renameDay(day),
                    child: Text(day.name, style: AppTextStyles.titleMedium),
                  ),
                ),
                Text('${day.exercises.length} ejerc.',
                    style: AppTextStyles.bodySmall),
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      size: 16, color: AppColors.textDisabled),
                  onPressed: () => _renameDay(day),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppColors.error.withValues(alpha: 0.7)),
                  onPressed: () => _deleteDay(day),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Ejercicios ────────────────────────────────────────────
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text('Sin ejercicios',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled)),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIdx, newIdx) async {
                await RoutineStore.reorderExercise(
                    widget.routineId, day.id, oldIdx, newIdx);
                _refresh();
              },
              itemCount: day.exercises.length,
              itemBuilder: (_, ei) {
                final ex = day.exercises[ei];
                final setsCount = ex.sets.length;
                final reps =
                    ex.sets.isNotEmpty ? ex.sets.first.reps : 0;
                return ListTile(
                  key: ValueKey('${day.id}_$ei'),
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  leading: ReorderableDragStartListener(
                    index: ei,
                    child: const Icon(Icons.drag_handle_rounded,
                        size: 18, color: AppColors.textDisabled),
                  ),
                  title: Text(ex.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary)),
                  subtitle: Text(ex.muscle,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _editSetsReps(day, ei),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${setsCount}×$reps',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryLight),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            size: 16,
                            color: AppColors.error.withValues(alpha: 0.7)),
                        onPressed: () async {
                          await RoutineStore.removeExercise(
                              widget.routineId, day.id, ei);
                          _refresh();
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                );
              },
            ),
          // ── Agregar ejercicio ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: OutlinedButton.icon(
              onPressed: () => _openExercisePicker(day),
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
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _RoutineNameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  const _RoutineNameField(
      {required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.titleMedium,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        border: InputBorder.none,
      ),
    );
  }
}

class _NameDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  const _NameDialog(
      {required this.title, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppTextStyles.titleMedium),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        onSubmitted: (_) => Navigator.pop(context, controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: AppTextStyles.titleLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }
}

// ─── Exercise Picker (reutilizado desde CreateRoutineScreen) ──────────────────

class _ExercisePickerSheet extends StatefulWidget {
  final Set<String> alreadyAdded;
  final ValueChanged<List<ExerciseCatalogEntry>> onConfirm;
  const _ExercisePickerSheet(
      {required this.alreadyAdded, required this.onConfirm});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';
  String? _filterGroup;
  final Set<String> _pending = {};

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
      _filtered.where((e) => !widget.alreadyAdded.contains(e.name)).toList();

  bool get _allSelected =>
      _filteredSelectable.isNotEmpty &&
      _filteredSelectable.every((e) => _pending.contains(e.id));

  void _toggle(ExerciseCatalogEntry e) => setState(() {
        _pending.contains(e.id) ? _pending.remove(e.id) : _pending.add(e.id);
      });

  void _toggleAll() => setState(() {
        if (_allSelected) {
          for (final e in _filteredSelectable) _pending.remove(e.id);
        } else {
          for (final e in _filteredSelectable) _pending.add(e.id);
        }
      });

  void _confirm() {
    widget.onConfirm(
        ExerciseCatalog.all.where((e) => _pending.contains(e.id)).toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectable = _filteredSelectable;
    final count = _pending.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Agregar ejercicios',
                          style: AppTextStyles.titleMedium),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count seleccionado${count == 1 ? '' : 's'}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primaryLight, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o músculo...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDisabled),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF3F3F46), width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF3F3F46), width: 0.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF3D2260), width: 1)),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Todos', null),
                      ...ExerciseCatalog.muscleGroups
                          .map((g) => _chip(g, g)),
                    ],
                  ),
                ),
                if (selectable.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _toggleAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _allSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: _allSelected
                                ? AppColors.primaryLight
                                : AppColors.textDisabled,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _allSelected
                                ? 'Deseleccionar todos'
                                : 'Seleccionar todos',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _allSelected
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Sin resultados para "$_query"',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textDisabled)))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      final isAdded = widget.alreadyAdded.contains(e.name);
                      final isPending = _pending.contains(e.id);
                      return ListTile(
                        dense: true,
                        enabled: !isAdded,
                        onTap: isAdded ? null : () => _toggle(e),
                        leading: isAdded
                            ? const Icon(Icons.check_circle_rounded,
                                size: 18, color: AppColors.textDisabled)
                            : isPending
                                ? const Icon(Icons.check_box_rounded,
                                    size: 18, color: AppColors.primaryLight)
                                : const Icon(
                                    Icons.check_box_outline_blank_rounded,
                                    size: 18,
                                    color: AppColors.textDisabled),
                        title: Text(e.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isAdded
                                  ? AppColors.textDisabled
                                  : isPending
                                      ? AppColors.primaryLight
                                      : AppColors.textPrimary,
                              fontWeight: isPending
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                        subtitle: Text(
                          '${e.muscleGroup} · ${e.equipment} · ${e.defaultSets}×${e.defaultReps}',
                          style:
                              AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                        tileColor: isPending
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : null,
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
            child: FilledButton(
              onPressed: count > 0 ? _confirm : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                count == 0
                    ? 'Selecciona ejercicios'
                    : 'Agregar $count ejercicio${count == 1 ? '' : 's'}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: count > 0
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

  Widget _chip(String label, String? group) {
    final selected = _filterGroup == group;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => _filterGroup = group),
        labelStyle: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 11),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        side: BorderSide(
            color: selected ? AppColors.primaryLight : const Color(0xFF3F3F46),
            width: selected ? 1.0 : 0.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
