// Enums de categorización para AtlasExercise.
// Fuente de verdad para grupos musculares, equipamiento,
// dificultad y patrón de movimiento en toda la app.

enum MuscleGroup {
  pecho,
  espalda,
  hombros,
  biceps,
  triceps,
  cuadriceps,
  isquiotibiales,
  gluteos,
  pantorrillas,
  core,
  fullBody;

  String get displayName => switch (this) {
        MuscleGroup.pecho          => 'Pecho',
        MuscleGroup.espalda        => 'Espalda',
        MuscleGroup.hombros        => 'Hombros',
        MuscleGroup.biceps         => 'Bíceps',
        MuscleGroup.triceps        => 'Tríceps',
        MuscleGroup.cuadriceps     => 'Cuádriceps',
        MuscleGroup.isquiotibiales => 'Isquiotibiales',
        MuscleGroup.gluteos        => 'Glúteos',
        MuscleGroup.pantorrillas   => 'Pantorrillas',
        MuscleGroup.core           => 'Core',
        MuscleGroup.fullBody       => 'Cuerpo completo',
      };
}

enum Equipment {
  barra,
  mancuernas,
  maquina,
  cable,
  pesoCorporal,
  banda,
  kettlebell,
  ninguno;

  String get displayName => switch (this) {
        Equipment.barra        => 'Barra',
        Equipment.mancuernas   => 'Mancuernas',
        Equipment.maquina      => 'Máquina',
        Equipment.cable        => 'Cable',
        Equipment.pesoCorporal => 'Peso corporal',
        Equipment.banda        => 'Banda',
        Equipment.kettlebell   => 'Kettlebell',
        Equipment.ninguno      => 'Sin equipo',
      };
}

enum Difficulty {
  principiante,
  intermedio,
  avanzado;

  String get displayName => switch (this) {
        Difficulty.principiante => 'Principiante',
        Difficulty.intermedio   => 'Intermedio',
        Difficulty.avanzado     => 'Avanzado',
      };
}

enum TrainingGoal {
  hypertrophy,
  fatLoss,
  strength,
  health,
  athletic;

  String get displayName => switch (this) {
        TrainingGoal.hypertrophy => 'Ganar músculo',
        TrainingGoal.fatLoss     => 'Perder grasa',
        TrainingGoal.strength    => 'Ganar fuerza',
        TrainingGoal.health      => 'Mejorar salud',
        TrainingGoal.athletic    => 'Rendimiento deportivo',
      };
}

enum MovementPattern {
  compound,
  isolation,
  cardio,
  mobility;

  String get displayName => switch (this) {
        MovementPattern.compound  => 'Compuesto',
        MovementPattern.isolation => 'Aislamiento',
        MovementPattern.cardio    => 'Cardio',
        MovementPattern.mobility  => 'Movilidad',
      };
}
