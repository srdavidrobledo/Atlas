import '../../../shared/mock_data.dart';
import '../../workout/data/workout_session_store.dart';

/// Gestión de rutinas en memoria.
///
/// Mantiene su propio _activeRoutineId para no depender del campo
/// MockRoutine.isActive (final/inmutable). Cuando los modelos sean
/// mutables este store se simplifica sin cambiar su interfaz pública.
class RoutineStore {
  // ID de la rutina actualmente activa.
  // Se inicializa desde el primer MockRoutine con isActive == true.
  static String _activeRoutineId =
      MockData.routines.firstWhere((r) => r.isActive).id;

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
    return routine;
  }

  /// Elimina la rutina con el [id] dado.
  /// Lanza [StateError] si se intenta eliminar la rutina activa.
  static void deleteRoutine(String id) {
    if (id == _activeRoutineId) {
      throw StateError('No se puede eliminar la rutina activa.');
    }
    MockData.routines.removeWhere((r) => r.id == id);
  }
}
