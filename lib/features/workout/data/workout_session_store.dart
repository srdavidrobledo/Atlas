import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../shared/mock_data.dart';
import '../../../core/storage/atlas_storage.dart';

class WorkoutSessionStore {
  static ActiveWorkoutSession? activeSession;
  static SavedWorkoutSession? lastSavedSession;

  static final List<SavedWorkoutSession> sessions = [];

  static Future<void> init() async {
    final raw = AtlasStorage.sessions.get('all') as String?;
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      sessions.addAll(list.map((item) => SavedWorkoutSession.fromJson(Map<String, dynamic>.from(item as Map))));
    }
  }

  static Future<void> _persistSessions() async {
    await AtlasStorage.sessions.put('all', jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  // Fuente única de verdad para rutina y día seleccionados
  static MockRoutine activeRoutine =
      MockData.routines.firstWhere((r) => r.isActive);

  static MockRoutineDay? _activeDay;

  // Callback para notificar a oyentes cuando el día activo cambia
  static VoidCallback? onActiveDayChanged;

  static MockRoutineDay get activeDay {
    _activeDay ??= activeRoutine.days.first;
    return _activeDay!;
  }

  static set activeDay(MockRoutineDay day) {
    _activeDay = day;
    unawaited(AtlasStorage.settings.put('active_day_id', day.id));
    onActiveDayChanged?.call();
  }

  static ActiveWorkoutSession startSession({
    required MockRoutine routine,
    required MockRoutineDay day,
  }) {
    final session = ActiveWorkoutSession(
      routineId: routine.id,
      routineName: routine.name,
      dayId: day.id,
      dayName: day.name,
      startedAt: DateTime.now(),
      exercises: day.exercises.map(SessionExercise.fromMock).toList(),
    );
    activeSession = session;
    return session;
  }

  static ActiveWorkoutSession ensureSession() {
    if (activeSession != null) return activeSession!;
    return startSession(
      routine: activeRoutine,
      day: activeDay,
    );
  }

  static void finishSession({required int elapsedSeconds}) {
    final session = ensureSession();
    session.elapsedSeconds = elapsedSeconds;
    session.finishedAt = DateTime.now();
  }

  static Future<void> saveSession({String? feeling, String? notes}) async {
    final session = ensureSession();
    final stats = _buildExerciseStats(session);
    final highlight = computeHighlight(session);

    final saved = SavedWorkoutSession(
      routineName: session.routineName,
      dayName: session.dayName,
      savedAt: DateTime.now(),
      durationSeconds: session.elapsedSeconds,
      exerciseCount: session.exerciseCount,
      completedSets: session.completedSets,
      totalVolume: session.totalVolume,
      exerciseStats: stats,
      highlight: highlight,
      feeling: feeling,
      notes: notes,
    );
    lastSavedSession = saved;
    sessions.insert(0, saved);
    activeSession = null;
    await _persistSessions();
  }

  // ─── Helpers de cálculo ────────────────────────────────────────────────

  /// Construye estadísticas por ejercicio a partir de la sesión activa.
  static List<ExerciseStat> _buildExerciseStats(ActiveWorkoutSession session) {
    return session.exercises.map((ex) {
      final done = ex.sets.where((s) => s.done).toList();
      if (done.isEmpty) {
        return ExerciseStat(
          name: ex.name,
          maxKg: 0,
          repsAtMaxKg: 0,
          totalVolume: 0,
        );
      }
      final maxSet = done.reduce((a, b) => a.kg >= b.kg ? a : b);
      final vol = done.fold(0.0, (sum, s) => sum + s.kg * s.reps);
      return ExerciseStat(
        name: ex.name,
        maxKg: maxSet.kg,
        repsAtMaxKg: maxSet.reps,
        totalVolume: vol,
      );
    }).toList();
  }

  /// Calcula el destacado comparando la sesión actual contra el historial.
  /// Puede llamarse antes de saveSession() para mostrar en el resumen.
  static SessionHighlight? computeHighlight(ActiveWorkoutSession session) {
    final stats = _buildExerciseStats(session);
    final active = stats.where((s) => s.maxKg > 0).toList();
    if (active.isEmpty) return null;

    SessionHighlight? bestWithHistory;
    double bestPct = double.negativeInfinity;
    SessionHighlight? firstTimeCandidate;

    for (final stat in active) {
      // Busca la referencia previa más reciente para este ejercicio
      ExerciseStat? prev;
      for (final saved in sessions) {
        final match = saved.exerciseStats
            .where((e) => e.name == stat.name)
            .firstOrNull;
        if (match != null && match.maxKg > 0) {
          prev = match;
          break;
        }
      }

      if (prev == null) {
        // Primera vez — candidato de fallback
        firstTimeCandidate ??= SessionHighlight(
          exerciseName: stat.name,
          currentKg: stat.maxKg,
          currentReps: stat.repsAtMaxKg,
          improvementPercent: null,
        );
      } else {
        final pct = (stat.maxKg - prev.maxKg) / prev.maxKg * 100;
        if (pct > bestPct) {
          bestPct = pct;
          bestWithHistory = SessionHighlight(
            exerciseName: stat.name,
            currentKg: stat.maxKg,
            currentReps: stat.repsAtMaxKg,
            improvementPercent: pct,
          );
        }
      }
    }

    // Prioridad: cualquier resultado con historial > primera vez
    return bestWithHistory ?? firstTimeCandidate;
  }
}

// ─── Modelos de sesión activa ──────────────────────────────────────────────

class ActiveWorkoutSession {
  final String routineId;
  final String routineName;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  final List<SessionExercise> exercises;
  DateTime? finishedAt;
  int elapsedSeconds;
  bool started;

  ActiveWorkoutSession({
    required this.routineId,
    required this.routineName,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    required this.exercises,
    this.finishedAt,
    this.elapsedSeconds = 0,
    this.started = false,
  });

  int get exerciseCount => exercises.length;

  int get totalSets =>
      exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  int get completedSets =>
      exercises.fold(0, (sum, ex) => sum + ex.sets.where((s) => s.done).length);

  double get progress => totalSets == 0 ? 0 : completedSets / totalSets;

  double get totalVolume =>
      exercises.fold(0.0, (sum, ex) => sum + ex.completedVolume);

  bool get isComplete => completedSets >= totalSets && totalSets > 0;

  /// Mayor peso levantado en cualquier set completado de la sesión.
  double get maxWeightLifted {
    double max = 0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (s.done && s.kg > max) max = s.kg;
      }
    }
    return max;
  }
}

class SessionExercise {
  final String name;
  final String muscle;
  final double suggestedKg;
  final int suggestedReps;
  final List<SessionSet> sets;

  SessionExercise({
    required this.name,
    required this.muscle,
    required this.suggestedKg,
    required this.suggestedReps,
    required this.sets,
  });

  factory SessionExercise.fromMock(MockExercise exercise) {
    final suggestedKg = exercise.prevKg + 2.5;
    return SessionExercise(
      name: exercise.name,
      muscle: exercise.muscle,
      suggestedKg: suggestedKg,
      suggestedReps: exercise.prevReps,
      sets: exercise.sets.map((set) {
        return SessionSet(
          kg: set.kg > 0 ? set.kg : suggestedKg,
          reps: set.reps > 0 ? set.reps : exercise.prevReps,
          rir: null,
          done: false,
        );
      }).toList(),
    );
  }

  int get targetSets => sets.length;

  int get completedSets => sets.where((s) => s.done).length;

  double get completedVolume =>
      sets.where((s) => s.done).fold(0.0, (sum, s) => sum + s.kg * s.reps);
}

class SessionSet {
  double kg;
  int reps;
  int? rir;
  bool done;

  SessionSet({
    required this.kg,
    required this.reps,
    this.rir,
    this.done = false,
  });
}

// ─── Modelos de sesión guardada ────────────────────────────────────────────

/// Estadísticas por ejercicio dentro de una sesión guardada.
class ExerciseStat {
  final String name;
  final double maxKg;
  final int repsAtMaxKg;
  final double totalVolume;

  const ExerciseStat({
    required this.name,
    required this.maxKg,
    required this.repsAtMaxKg,
    required this.totalVolume,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'maxKg': maxKg,
    'repsAtMaxKg': repsAtMaxKg,
    'totalVolume': totalVolume,
  };

  factory ExerciseStat.fromJson(Map<String, dynamic> m) => ExerciseStat(
    name: m['name'] as String,
    maxKg: (m['maxKg'] as num).toDouble(),
    repsAtMaxKg: m['repsAtMaxKg'] as int,
    totalVolume: (m['totalVolume'] as num).toDouble(),
  );
}

/// Ejercicio destacado de la sesión: el de mayor mejora vs referencia previa.
class SessionHighlight {
  final String exerciseName;
  final double currentKg;
  final int currentReps;

  /// null → primera vez que se registra este ejercicio.
  final double? improvementPercent;

  const SessionHighlight({
    required this.exerciseName,
    required this.currentKg,
    required this.currentReps,
    required this.improvementPercent,
  });

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'currentKg': currentKg,
    'currentReps': currentReps,
    'improvementPercent': improvementPercent,
  };

  factory SessionHighlight.fromJson(Map<String, dynamic> m) => SessionHighlight(
    exerciseName: m['exerciseName'] as String,
    currentKg: (m['currentKg'] as num).toDouble(),
    currentReps: m['currentReps'] as int,
    improvementPercent: m['improvementPercent'] != null ? (m['improvementPercent'] as num).toDouble() : null,
  );
}

class SavedWorkoutSession {
  final String routineName;
  final String dayName;
  final DateTime savedAt;
  final int durationSeconds;
  final int exerciseCount;
  final int completedSets;
  final double totalVolume;
  final List<ExerciseStat> exerciseStats;
  final SessionHighlight? highlight;
  final String? feeling;
  final String? notes;

  SavedWorkoutSession({
    required this.routineName,
    required this.dayName,
    required this.savedAt,
    required this.durationSeconds,
    required this.exerciseCount,
    required this.completedSets,
    required this.totalVolume,
    required this.exerciseStats,
    this.highlight,
    this.feeling,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'routineName': routineName,
    'dayName': dayName,
    'savedAt': savedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exerciseCount': exerciseCount,
    'completedSets': completedSets,
    'totalVolume': totalVolume,
    'exerciseStats': exerciseStats.map((e) => e.toJson()).toList(),
    'highlight': highlight?.toJson(),
    'feeling': feeling,
    'notes': notes,
  };

  factory SavedWorkoutSession.fromJson(Map<String, dynamic> m) => SavedWorkoutSession(
    routineName: m['routineName'] as String,
    dayName: m['dayName'] as String,
    savedAt: DateTime.parse(m['savedAt'] as String),
    durationSeconds: m['durationSeconds'] as int,
    exerciseCount: m['exerciseCount'] as int,
    completedSets: m['completedSets'] as int,
    totalVolume: (m['totalVolume'] as num).toDouble(),
    exerciseStats: (m['exerciseStats'] as List)
        .map((e) => ExerciseStat.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    highlight: m['highlight'] != null
        ? SessionHighlight.fromJson(Map<String, dynamic>.from(m['highlight'] as Map))
        : null,
    feeling: m['feeling'] as String?,
    notes: m['notes'] as String?,
  );
}
