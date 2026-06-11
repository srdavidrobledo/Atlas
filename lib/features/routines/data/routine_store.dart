import 'dart:async';
import 'dart:convert';
import '../../../shared/mock_data.dart';
import '../../../core/storage/atlas_storage.dart';
import '../../workout/data/workout_session_store.dart';

/// Gestión de rutinas en memoria.
///
/// Mantiene su propio _activeRoutineId para no depender del campo
/// MockRoutine.isActive (final/inmutable). Cuando los modelos sean
/// mutables este store se simplifica sin cambiar su interfaz pública.
class RoutineStore {
  // Null hasta que RoutineStore.init() restaure el ID desde Hive,
  // o hasta que onboarding llame a activateRoutine().
  static String? _activeRoutineId;

  static Future<void> init() async {
    final raw = AtlasStorage.routines.get('user_routines') as String?;
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final routine = MockRoutine.fromJson(Map<String, dynamic>.from(item as Map));
        if (!MockData.routines.any((r) => r.id == routine.id)) {
          MockData.routines.add(routine);
        }
      }
    }
    final savedId = AtlasStorage.settings.get('active_routine_id') as String?;
    if (savedId != null && MockData.routines.any((r) => r.id == savedId)) {
      _activeRoutineId = savedId;
      WorkoutSessionStore.activeRoutine = MockData.routines.firstWhere((r) => r.id == savedId);
    }
    final savedDayId = AtlasStorage.settings.get('active_day_id') as String?;
    if (savedDayId != null) {
      final day = WorkoutSessionStore.activeRoutine.days
          .where((d) => d.id == savedDayId)
          .firstOrNull;
      if (day != null) WorkoutSessionStore.activeDay = day;
    }
  }

  static Future<void> persistRoutines() async {
    final userRoutines = MockData.routines
        .where((r) => r.id.startsWith('r_'))
        .map((r) => r.toJson())
        .toList();
    await AtlasStorage.routines.put('user_routines', jsonEncode(userRoutines));
  }

  // ── Getters ──────────────────────────────────────────────────────────

  /// Todas las rutinas disponibles.
  static List<MockRoutine> get all => MockData.routines;

  /// Rutina activa actual.
  /// Lanza [StateError] solo si no hay ninguna rutina cargada,
  /// situación que el router previene redirigiendo al onboarding.
  static MockRoutine get active {
    if (MockData.routines.isEmpty) {
      throw StateError('No hay rutinas disponibles.');
    }
    if (_activeRoutineId == null) return MockData.routines.first;
    return MockData.routines.firstWhere(
      (r) => r.id == _activeRoutineId,
      orElse: () => MockData.routines.first,
    );
  }

  // ── Rutinas ──────────────────────────────────────────────────────────

  /// Activa la rutina con el [id] dado.
  /// Actualiza WorkoutSessionStore para mantener sincronía.
  /// No hace nada si ya es la rutina activa.
  static void activateRoutine(String id) {
    if (_activeRoutineId == id) return;
    if (!MockData.routines.any((r) => r.id == id)) return;
    _activeRoutineId = id;
    WorkoutSessionStore.activeRoutine = active;
    unawaited(AtlasStorage.settings.put('active_routine_id', id));
  }

  /// Crea una nueva rutina vacía con el [name] dado.
  /// La añade a la lista de rutinas y la retorna.
  static MockRoutine createRoutine(String name) {
    final routine = MockRoutine(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isActive: false,
      days: [],
      totalSessions: 0,
      lastUsed: 'Nunca',
    );
    MockData.routines.add(routine);
    // No persistir aquí: los días se añaden después en CreateRoutineScreen.
    // persistRoutines() se llama explícitamente allí una vez completa.
    return routine;
  }

  /// Añade una rutina pre-construida (e.g. generada por AtlasRoutineGenerator).
  /// No hace nada si ya existe una rutina con el mismo ID.
  static Future<void> addRoutine(MockRoutine routine) async {
    if (MockData.routines.any((r) => r.id == routine.id)) return;
    MockData.routines.add(routine);
    await persistRoutines();
  }

  static Future<void> deleteRoutine(String id) async {
    if (id == _activeRoutineId) {
      throw StateError('No se puede eliminar la rutina activa.');
    }
    MockData.routines.removeWhere((r) => r.id == id);
    await persistRoutines();
  }

  static Future<void> renameRoutine(String id, String newName) async {
    final idx = MockData.routines.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = MockData.routines[idx];
    MockData.routines[idx] = MockRoutine(
      id: r.id, name: newName, isActive: r.isActive,
      days: r.days, totalSessions: r.totalSessions, lastUsed: r.lastUsed,
    );
    if (id == _activeRoutineId) WorkoutSessionStore.activeRoutine = MockData.routines[idx];
    await persistRoutines();
  }

  static Future<void> duplicateRoutine(String id) async {
    final src = MockData.routines.firstWhere((r) => r.id == id);
    final newId = 'r_${DateTime.now().millisecondsSinceEpoch}';
    final copy = MockRoutine(
      id: newId,
      name: '${src.name} (copia)',
      isActive: false,
      days: src.days.map((d) => MockRoutineDay(
        id: 'day_${newId}_${d.id}',
        name: d.name,
        exercises: List.from(d.exercises),
      )).toList(),
      totalSessions: 0,
      lastUsed: 'Nunca',
    );
    MockData.routines.add(copy);
    await persistRoutines();
  }

  // ── Días ─────────────────────────────────────────────────────────────

  static Future<void> addDay(String routineId, String dayName) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final dayId = 'day_${routineId}_${DateTime.now().millisecondsSinceEpoch}';
    r.days.add(MockRoutineDay(id: dayId, name: dayName, exercises: []));
    await persistRoutines();
  }

  static Future<void> removeDay(String routineId, String dayId) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    r.days.removeWhere((d) => d.id == dayId);
    await persistRoutines();
  }

  static Future<void> renameDay(String routineId, String dayId, String newName) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final idx = r.days.indexWhere((d) => d.id == dayId);
    if (idx == -1) return;
    final d = r.days[idx];
    r.days[idx] = MockRoutineDay(id: d.id, name: newName, exercises: d.exercises);
    await persistRoutines();
  }

  static Future<void> reorderDay(String routineId, int oldIndex, int newIndex) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final day = r.days.removeAt(oldIndex);
    r.days.insert(newIndex, day);
    await persistRoutines();
  }

  // ── Ejercicios ────────────────────────────────────────────────────────

  static Future<void> addExercise(String routineId, String dayId, MockExercise exercise) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final d = r.days.firstWhere((d) => d.id == dayId);
    d.exercises.add(exercise);
    await persistRoutines();
  }

  static Future<void> removeExercise(String routineId, String dayId, int exerciseIndex) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final d = r.days.firstWhere((d) => d.id == dayId);
    d.exercises.removeAt(exerciseIndex);
    await persistRoutines();
  }

  static Future<void> reorderExercise(String routineId, String dayId, int oldIndex, int newIndex) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final d = r.days.firstWhere((d) => d.id == dayId);
    final ex = d.exercises.removeAt(oldIndex);
    d.exercises.insert(newIndex, ex);
    await persistRoutines();
  }

  static Future<void> updateExercise(
    String routineId, String dayId, int exerciseIndex, MockExercise updated,
  ) async {
    final r = MockData.routines.firstWhere((r) => r.id == routineId);
    final d = r.days.firstWhere((d) => d.id == dayId);
    d.exercises[exerciseIndex] = updated;
    await persistRoutines();
  }
}
