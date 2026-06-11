import '../../../shared/exercises/atlas_exercise.dart';
import '../../../shared/exercises/exercise_categories.dart';
import '../../../shared/exercises/exercise_search.dart';
import '../../../shared/mock_data.dart';
import '../models/onboarding_models.dart';
import 'training_split.dart';

// ── VolumeScheme ───────────────────────────────────────────────────────────────

class VolumeScheme {
  final int sets;
  final int reps;
  final int restSeconds;
  final int? rir;
  final int minExercisesPerDay;
  final int maxExercisesPerDay;
  final bool isolationAllowed;

  const VolumeScheme({
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.rir,
    required this.minExercisesPerDay,
    required this.maxExercisesPerDay,
    this.isolationAllowed = true,
  });

  static VolumeScheme forGoalAndExperience(
          TrainingGoal goal, Difficulty experience) =>
      switch ((goal, experience)) {
        (TrainingGoal.health, _) => const VolumeScheme(
            sets: 3,
            reps: 12,
            restSeconds: 60,
            minExercisesPerDay: 4,
            maxExercisesPerDay: 5),

        (TrainingGoal.hypertrophy, Difficulty.principiante) => const VolumeScheme(
            sets: 3,
            reps: 12,
            restSeconds: 75,
            minExercisesPerDay: 4,
            maxExercisesPerDay: 5),
        (TrainingGoal.hypertrophy, Difficulty.intermedio) => const VolumeScheme(
            sets: 4,
            reps: 10,
            restSeconds: 90,
            rir: 2,
            minExercisesPerDay: 5,
            maxExercisesPerDay: 6),
        (TrainingGoal.hypertrophy, Difficulty.avanzado) => const VolumeScheme(
            sets: 4,
            reps: 8,
            restSeconds: 90,
            rir: 1,
            minExercisesPerDay: 6,
            maxExercisesPerDay: 7),

        (TrainingGoal.strength, Difficulty.principiante) => const VolumeScheme(
            sets: 3,
            reps: 6,
            restSeconds: 120,
            minExercisesPerDay: 3,
            maxExercisesPerDay: 4,
            isolationAllowed: false),
        (TrainingGoal.strength, Difficulty.intermedio) => const VolumeScheme(
            sets: 4,
            reps: 5,
            restSeconds: 150,
            rir: 1,
            minExercisesPerDay: 4,
            maxExercisesPerDay: 5),
        (TrainingGoal.strength, Difficulty.avanzado) => const VolumeScheme(
            sets: 5,
            reps: 4,
            restSeconds: 180,
            rir: 0,
            minExercisesPerDay: 4,
            maxExercisesPerDay: 5),

        (TrainingGoal.fatLoss, Difficulty.principiante) => const VolumeScheme(
            sets: 3,
            reps: 15,
            restSeconds: 45,
            minExercisesPerDay: 5,
            maxExercisesPerDay: 6),
        (TrainingGoal.fatLoss, Difficulty.intermedio) => const VolumeScheme(
            sets: 3,
            reps: 12,
            restSeconds: 45,
            minExercisesPerDay: 5,
            maxExercisesPerDay: 6),
        (TrainingGoal.fatLoss, Difficulty.avanzado) => const VolumeScheme(
            sets: 4,
            reps: 12,
            restSeconds: 45,
            minExercisesPerDay: 6,
            maxExercisesPerDay: 7),

        (TrainingGoal.athletic, Difficulty.principiante) => const VolumeScheme(
            sets: 3,
            reps: 8,
            restSeconds: 90,
            minExercisesPerDay: 4,
            maxExercisesPerDay: 5,
            isolationAllowed: false),
        (TrainingGoal.athletic, Difficulty.intermedio) => const VolumeScheme(
            sets: 4,
            reps: 6,
            restSeconds: 90,
            rir: 1,
            minExercisesPerDay: 5,
            maxExercisesPerDay: 6),
        (TrainingGoal.athletic, Difficulty.avanzado) => const VolumeScheme(
            sets: 5,
            reps: 5,
            restSeconds: 120,
            rir: 0,
            minExercisesPerDay: 5,
            maxExercisesPerDay: 6),
      };
}

// ── _ExerciseSelector ──────────────────────────────────────────────────────────

class _ExerciseSelector {
  const _ExerciseSelector._();

  /// Selecciona ejercicios para un día completo según la especificación.
  /// Muta [usedIds] añadiendo los IDs seleccionados.
  static List<AtlasExercise> pickForDay({
    required DaySpec daySpec,
    required TrainingGoal goal,
    required Difficulty experience,
    required VolumeScheme scheme,
    required Set<String> usedIds,
  }) {
    final result = <AtlasExercise>[];

    // Fase 1: un ejercicio por grupo muscular primario
    for (final group in daySpec.primary) {
      if (result.length >= scheme.maxExercisesPerDay) break;
      final pref = (daySpec.isCardioDay && group == MuscleGroup.fullBody)
          ? MovementPattern.cardio
          : null;
      final e = _pickOne(
        group: group,
        goal: goal,
        experience: experience,
        usedIds: usedIds,
        preferredMovement: pref,
      );
      if (e != null) {
        result.add(e);
        usedIds.add(e.id);
      }
    }

    // Fase 2: grupos opcionales (hasta alcanzar minExercisesPerDay)
    for (final group in daySpec.optional) {
      if (result.length >= scheme.minExercisesPerDay) break;
      final e = _pickOne(
        group: group,
        goal: goal,
        experience: experience,
        usedIds: usedIds,
      );
      if (e != null) {
        result.add(e);
        usedIds.add(e.id);
      }
    }

    // Fase 3: pasada de aislamiento (si permitida y hay espacio)
    if (scheme.isolationAllowed && !daySpec.isCardioDay) {
      for (final group in daySpec.primary) {
        if (result.length >= scheme.maxExercisesPerDay) break;
        final e = _pickOne(
          group: group,
          goal: goal,
          experience: experience,
          usedIds: usedIds,
          preferredMovement: MovementPattern.isolation,
        );
        if (e != null) {
          result.add(e);
          usedIds.add(e.id);
        }
      }
    }

    return result;
  }

  /// Selecciona un ejercicio con cascada de relajación de 4 intentos.
  static AtlasExercise? _pickOne({
    required MuscleGroup group,
    required TrainingGoal goal,
    required Difficulty experience,
    required Set<String> usedIds,
    MovementPattern? preferredMovement,
  }) {
    // Intento 1: grupo + objetivo + dificultad exacta
    var pool = _sort(
      _exclude(
          ExerciseSearch.filter(
              muscleGroup: group, goal: goal, difficulty: experience),
          usedIds),
      preferredMovement,
    );
    if (pool.isNotEmpty) return pool.first;

    // Intento 2: grupo + objetivo, relajar dificultad
    pool = _sort(
      _exclude(ExerciseSearch.filter(muscleGroup: group, goal: goal), usedIds),
      preferredMovement,
    );
    if (pool.isNotEmpty) return pool.first;

    // Intento 3: solo grupo, relajar objetivo y dificultad
    pool = _sort(
      _exclude(ExerciseSearch.filter(muscleGroup: group), usedIds),
      preferredMovement,
    );
    if (pool.isNotEmpty) return pool.first;

    // Intento 4: solo grupo, ignorar usedIds (último recurso)
    pool = _sort(ExerciseSearch.filter(muscleGroup: group), preferredMovement);
    if (pool.isNotEmpty) return pool.first;

    return null;
  }

  static List<AtlasExercise> _exclude(
          List<AtlasExercise> pool, Set<String> usedIds) =>
      pool.where((e) => !usedIds.contains(e.id)).toList();

  /// Ordena priorizando el movimiento preferido; por defecto, compuestos primero.
  static List<AtlasExercise> _sort(
      List<AtlasExercise> pool, MovementPattern? pref) {
    if (pool.isEmpty) return pool;
    final sorted = [...pool];
    sorted.sort((a, b) {
      final target = pref ?? MovementPattern.compound;
      final sa = a.movement == target ? 0 : 1;
      final sb = b.movement == target ? 0 : 1;
      return sa.compareTo(sb);
    });
    return sorted;
  }
}

// ── AtlasRoutineGenerator ──────────────────────────────────────────────────────

class AtlasRoutineGenerator {
  const AtlasRoutineGenerator._();

  /// Genera la rutina inicial de Atlas a partir de los datos del onboarding.
  ///
  /// No contiene listas hardcodeadas de ejercicios: consume AtlasExerciseLibrary
  /// vía ExerciseSearch y escala automáticamente cuando la librería crece.
  static MockRoutine generate(OnboardingData data) {
    final goal = _mapGoal(data.goal);
    final experience = _mapExperience(data.experience);
    final split = TrainingSplit.forGoalAndDays(goal, data.trainingDays);
    final scheme = VolumeScheme.forGoalAndExperience(goal, experience);

    final usedIds = <String>{};
    final ts = DateTime.now().millisecondsSinceEpoch;
    final routineId = 'r_atlas_$ts';

    final days = <MockRoutineDay>[];
    for (var i = 0; i < split.length; i++) {
      final daySpec = split[i];
      final exercises = _ExerciseSelector.pickForDay(
        daySpec: daySpec,
        goal: goal,
        experience: experience,
        scheme: scheme,
        usedIds: usedIds,
      );
      days.add(MockRoutineDay(
        id: 'day_${routineId}_$i',
        name: daySpec.name,
        exercises: exercises.map((e) => _toMockExercise(e, scheme)).toList(),
      ));
    }

    return MockRoutine(
      id: routineId,
      name: _routineName(goal, experience),
      isActive: false,
      days: days,
      totalSessions: 0,
      lastUsed: 'Nunca',
    );
  }

  static MockExercise _toMockExercise(AtlasExercise e, VolumeScheme scheme) =>
      MockExercise(
        name: e.name,
        muscle: e.muscleLabel,
        sets: List.generate(
          scheme.sets,
          (_) => MockSet(
              kg: 0, reps: scheme.reps, rir: scheme.rir, done: false),
        ),
        prevKg: 0,
        prevReps: 0,
      );

  static String _routineName(TrainingGoal goal, Difficulty experience) {
    final suffix = switch (experience) {
      Difficulty.principiante => ' Básica',
      Difficulty.intermedio   => '',
      Difficulty.avanzado     => ' Avanzada',
    };
    return switch (goal) {
      TrainingGoal.hypertrophy => 'Atlas · Hipertrofia$suffix',
      TrainingGoal.fatLoss     => 'Atlas · Definición$suffix',
      TrainingGoal.strength    => 'Atlas · Fuerza$suffix',
      TrainingGoal.health      => 'Atlas · Bienestar',
      TrainingGoal.athletic    => 'Atlas · Rendimiento$suffix',
    };
  }

  static TrainingGoal _mapGoal(String goal) => switch (goal) {
        'Ganar músculo'         => TrainingGoal.hypertrophy,
        'Perder grasa'          => TrainingGoal.fatLoss,
        'Ganar fuerza'          => TrainingGoal.strength,
        'Mejorar salud'         => TrainingGoal.health,
        'Rendimiento deportivo' => TrainingGoal.athletic,
        _                       => TrainingGoal.hypertrophy,
      };

  static Difficulty _mapExperience(String experience) => switch (experience) {
        'Principiante' => Difficulty.principiante,
        'Intermedio'   => Difficulty.intermedio,
        'Avanzado'     => Difficulty.avanzado,
        _              => Difficulty.principiante,
      };
}
