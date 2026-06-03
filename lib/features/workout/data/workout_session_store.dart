import 'package:flutter/foundation.dart';
import '../../../shared/mock_data.dart';

class WorkoutSessionStore {
  static ActiveWorkoutSession? activeSession;
  static SavedWorkoutSession? lastSavedSession;

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
    if (activeSession != null) {
      // Sesión ya iniciada → nunca descartarla
      if (activeSession!.started) return activeSession!;
      // Sesión preparada pero para otro día → descartarla
      if (activeSession!.dayId != activeDay.id) activeSession = null;
    }
    return activeSession ??
        startSession(
          routine: activeRoutine,
          day: activeDay,
        );
  }

  static void finishSession({required int elapsedSeconds}) {
    final session = ensureSession();
    session.elapsedSeconds = elapsedSeconds;
    session.finishedAt = DateTime.now();
  }

  static void saveSession({String? feeling, String? notes}) {
    final session = ensureSession();
    lastSavedSession = SavedWorkoutSession(
      routineName: session.routineName,
      dayName: session.dayName,
      savedAt: DateTime.now(),
      durationSeconds: session.elapsedSeconds,
      exerciseCount: session.exerciseCount,
      completedSets: session.completedSets,
      totalVolume: session.totalVolume,
      bestExerciseName: session.bestExerciseName,
      feeling: feeling,
      notes: notes,
    );
    activeSession = null;
  }
}

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

  int get totalSets => exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  int get completedSets {
    return exercises.fold(0, (sum, exercise) {
      return sum + exercise.sets.where((set) => set.done).length;
    });
  }

  double get progress => totalSets == 0 ? 0 : completedSets / totalSets;

  double get totalVolume {
    return exercises.fold(0, (sum, exercise) => sum + exercise.completedVolume);
  }

  String get bestExerciseName {
    if (exercises.isEmpty) return 'Sin datos';
    final ranked = [...exercises]..sort((a, b) => b.completedVolume.compareTo(a.completedVolume));
    return ranked.first.completedVolume > 0 ? ranked.first.name : exercises.first.name;
  }

  bool get isComplete => completedSets >= totalSets && totalSets > 0;
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

  int get completedSets => sets.where((set) => set.done).length;

  double get completedVolume {
    return sets.where((set) => set.done).fold(0, (sum, set) => sum + (set.kg * set.reps));
  }
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

class SavedWorkoutSession {
  final String routineName;
  final String dayName;
  final DateTime savedAt;
  final int durationSeconds;
  final int exerciseCount;
  final int completedSets;
  final double totalVolume;
  final String bestExerciseName;
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
    required this.bestExerciseName,
    this.feeling,
    this.notes,
  });
}
