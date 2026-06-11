import '../../../shared/exercises/exercise_categories.dart';

/// Especificación de un día de entrenamiento en una rutina generada.
class DaySpec {
  final String name;
  final List<MuscleGroup> primary;
  final List<MuscleGroup> optional;

  /// Si true, el selector prioriza MovementPattern.cardio para MuscleGroup.fullBody.
  final bool isCardioDay;

  const DaySpec({
    required this.name,
    required this.primary,
    this.optional = const [],
    this.isCardioDay = false,
  });
}

/// Produce la secuencia de días según objetivo y frecuencia semanal.
///
/// Nomenclatura: grupos musculares en español ("Pecho · Tríceps") en lugar de
/// terminología académica PPL/Upper-Lower. Los grupos focales del día aparecen
/// dos veces en [primary] para que el selector produzca 2 compuestos + 1
/// aislamiento para ese grupo, sin modificar el generador.
class TrainingSplit {
  const TrainingSplit._();

  static List<DaySpec> forGoalAndDays(TrainingGoal goal, int days) {
    if (goal == TrainingGoal.health) return _healthSplit(days);
    if (goal == TrainingGoal.strength && days <= 3) return _fullBodySplit(days);

    return switch (days) {
      2 => [_fbA, _fbB],
      3 => [_pechoEspalda, _piernasBase, _hombrosBrazos],
      4 => [_pechTric, _espBic, _piernasBase, _hombrosCore],
      5 => [_soloPecho, _soloEspalda, _piernasBase, _soloHombros, _brazosCore],
      6 => [_pechTric, _espBic, _piernasBase, _pechoHombros, _espaldaBrazos, _piernasCore],
      7 => [_pechTric, _espBic, _piernasBase, _soloHombros, _pechoEspalda, _piernasCore, _cardioRecup],
      _ => _fullBodySplit(days.clamp(2, 7)),
    };
  }

  static List<DaySpec> _fullBodySplit(int days) {
    const cycle = [_fbA, _fbB, _fbC];
    return List.generate(days, (i) => cycle[i % cycle.length]);
  }

  static List<DaySpec> _healthSplit(int days) => switch (days) {
        2 => [_fbA, _fbB],
        3 => [_fbA, _fbB, _fbC],
        4 => [_fbA, _fbB, _cardioDay, _coreDay],
        5 => [_fbA, _fbB, _cardioDay, _fbC, _coreDay],
        6 => [_fbA, _fbB, _cardioDay, _fbA, _fbB, _coreDay],
        7 => [_fbA, _fbB, _cardioDay, _coreDay, _fbA, _fbB, _cardioDay],
        _ => [_fbA, _fbB],
      };

  // ── Full Body ──────────────────────────────────────────────────────────────

  static const _fbA = DaySpec(
    name: 'Full Body A',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.espalda,
      MuscleGroup.cuadriceps,
      MuscleGroup.cuadriceps,
    ],
    optional: [MuscleGroup.core],
  );

  static const _fbB = DaySpec(
    name: 'Full Body B',
    primary: [
      MuscleGroup.hombros,
      MuscleGroup.espalda,
      MuscleGroup.isquiotibiales,
      MuscleGroup.gluteos,
    ],
    optional: [MuscleGroup.core],
  );

  static const _fbC = DaySpec(
    name: 'Full Body C',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.espalda,
      MuscleGroup.cuadriceps,
      MuscleGroup.pantorrillas,
    ],
    optional: [MuscleGroup.biceps, MuscleGroup.triceps],
  );

  // ── 3 días ─────────────────────────────────────────────────────────────────

  // Grupos focales listados 2× → Fase 1 elige 2 compuestos distintos por focal.
  static const _pechoEspalda = DaySpec(
    name: 'Pecho · Espalda',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.pecho,
      MuscleGroup.espalda,
      MuscleGroup.espalda,
    ],
    optional: [MuscleGroup.core],
  );

  static const _hombrosBrazos = DaySpec(
    name: 'Hombros · Brazos',
    primary: [
      MuscleGroup.hombros,
      MuscleGroup.hombros,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
    ],
    optional: [MuscleGroup.core],
  );

  // ── Piernas (compartido entre splits) ─────────────────────────────────────

  static const _piernasBase = DaySpec(
    name: 'Piernas',
    primary: [
      MuscleGroup.cuadriceps,
      MuscleGroup.cuadriceps,
      MuscleGroup.isquiotibiales,
      MuscleGroup.gluteos,
    ],
    optional: [MuscleGroup.pantorrillas, MuscleGroup.core],
  );

  // ── 4 días ─────────────────────────────────────────────────────────────────

  static const _pechTric = DaySpec(
    name: 'Pecho · Tríceps',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.pecho,
      MuscleGroup.triceps,
      MuscleGroup.triceps,
    ],
  );

  static const _espBic = DaySpec(
    name: 'Espalda · Bíceps',
    primary: [
      MuscleGroup.espalda,
      MuscleGroup.espalda,
      MuscleGroup.biceps,
      MuscleGroup.biceps,
    ],
  );

  static const _hombrosCore = DaySpec(
    name: 'Hombros · Core',
    primary: [
      MuscleGroup.hombros,
      MuscleGroup.hombros,
      MuscleGroup.core,
      MuscleGroup.core,
    ],
  );

  // ── 5 días ─────────────────────────────────────────────────────────────────

  static const _soloPecho = DaySpec(
    name: 'Pecho',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.pecho,
      MuscleGroup.pecho,
    ],
    optional: [MuscleGroup.triceps, MuscleGroup.core],
  );

  static const _soloEspalda = DaySpec(
    name: 'Espalda',
    primary: [
      MuscleGroup.espalda,
      MuscleGroup.espalda,
      MuscleGroup.espalda,
    ],
    optional: [MuscleGroup.biceps],
  );

  static const _soloHombros = DaySpec(
    name: 'Hombros',
    primary: [
      MuscleGroup.hombros,
      MuscleGroup.hombros,
      MuscleGroup.hombros,
    ],
    optional: [MuscleGroup.core],
  );

  static const _brazosCore = DaySpec(
    name: 'Brazos · Core',
    primary: [
      MuscleGroup.biceps,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.triceps,
      MuscleGroup.core,
    ],
  );

  // ── 6 días (extras sobre 4 días) ──────────────────────────────────────────

  static const _pechoHombros = DaySpec(
    name: 'Pecho · Hombros',
    primary: [
      MuscleGroup.pecho,
      MuscleGroup.pecho,
      MuscleGroup.hombros,
      MuscleGroup.hombros,
    ],
  );

  static const _espaldaBrazos = DaySpec(
    name: 'Espalda · Brazos',
    primary: [
      MuscleGroup.espalda,
      MuscleGroup.espalda,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
    ],
  );

  static const _piernasCore = DaySpec(
    name: 'Piernas · Core',
    primary: [
      MuscleGroup.cuadriceps,
      MuscleGroup.isquiotibiales,
      MuscleGroup.gluteos,
      MuscleGroup.core,
      MuscleGroup.core,
    ],
    optional: [MuscleGroup.pantorrillas],
  );

  // ── Días especiales (health + día 7) ──────────────────────────────────────

  static const _cardioRecup = DaySpec(
    name: 'Cardio · Recuperación',
    primary: [MuscleGroup.fullBody, MuscleGroup.core],
    isCardioDay: true,
  );

  static const _cardioDay = DaySpec(
    name: 'Cardio',
    primary: [MuscleGroup.fullBody],
    optional: [MuscleGroup.core],
    isCardioDay: true,
  );

  static const _coreDay = DaySpec(
    name: 'Core',
    primary: [MuscleGroup.core],
    optional: [MuscleGroup.fullBody],
  );
}
