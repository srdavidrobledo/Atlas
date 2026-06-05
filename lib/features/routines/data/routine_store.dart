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
  static String _activeRoutineId =
      MockData.routines.firstWhere((r) => r.isActive).id;

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
  static MockRoutine get active =>
      MockData.routines.firstWhere((r) => r.id == _activeRoutineId);

  // ── Rutinas ──────────────────────────────────────────────────────────

  /// Activa la rutina con el [id] dado.
  /// Actualiza WorkoutSessionStore para mantener sincronía.
  /// No hace nada si ya es la rutina activa.
  static void activateRoutine(String id) {
    if (id == _activeRoutineId) return;
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

  static Future<void> deleteRoutine(String id) async {
    if (id == _activeRoutineId) {
      throw StateError('No se puede eliminar la rutina activa.');
    }
    MockData.routines.removeWhere((r) => r.id == id);
    await persistRoutines();
  }
}
