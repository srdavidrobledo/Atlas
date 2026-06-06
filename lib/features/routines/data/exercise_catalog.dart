/// Catálogo de ejercicios reutilizable.
/// Independiente de mock_data.dart y de WorkoutSessionStore.
/// Fuente de verdad para el editor de rutinas y el picker de ejercicios.

class ExerciseCatalogEntry {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final int defaultSets;
  final int defaultReps;

  const ExerciseCatalogEntry({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.defaultSets,
    required this.defaultReps,
  });
}

class ExerciseCatalog {
  static const List<ExerciseCatalogEntry> all = [
    // ── Pecho ─────────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_pecho_001',
      name: 'Press de Banca',
      muscleGroup: 'Pecho',
      equipment: 'Barra',
      defaultSets: 4,
      defaultReps: 6,
    ),
    ExerciseCatalogEntry(
      id: 'ex_pecho_002',
      name: 'Press Inclinado',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_pecho_003',
      name: 'Aperturas',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 12,
    ),
    ExerciseCatalogEntry(
      id: 'ex_pecho_004',
      name: 'Fondos en paralelas',
      muscleGroup: 'Pecho',
      equipment: 'Peso corporal',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_pecho_005',
      name: 'Press con cable cruzado',
      muscleGroup: 'Pecho',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 12,
    ),

    // ── Espalda ───────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_espalda_001',
      name: 'Dominadas',
      muscleGroup: 'Espalda',
      equipment: 'Peso corporal',
      defaultSets: 3,
      defaultReps: 8,
    ),
    ExerciseCatalogEntry(
      id: 'ex_espalda_002',
      name: 'Remo con Barra',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      defaultSets: 4,
      defaultReps: 6,
    ),
    ExerciseCatalogEntry(
      id: 'ex_espalda_003',
      name: 'Remo con Mancuerna',
      muscleGroup: 'Espalda',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_espalda_004',
      name: 'Jalón al pecho',
      muscleGroup: 'Espalda',
      equipment: 'Máquina',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_espalda_005',
      name: 'Remo en polea baja',
      muscleGroup: 'Espalda',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 12,
    ),

    // ── Hombros ───────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_hombros_001',
      name: 'Press Militar',
      muscleGroup: 'Hombros',
      equipment: 'Barra',
      defaultSets: 4,
      defaultReps: 6,
    ),
    ExerciseCatalogEntry(
      id: 'ex_hombros_002',
      name: 'Press de hombros con mancuernas',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_hombros_003',
      name: 'Elevaciones laterales',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 15,
    ),
    ExerciseCatalogEntry(
      id: 'ex_hombros_004',
      name: 'Face pull',
      muscleGroup: 'Hombros',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 15,
    ),

    // ── Bíceps ────────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_biceps_001',
      name: 'Curl con Barra',
      muscleGroup: 'Bíceps',
      equipment: 'Barra',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_biceps_002',
      name: 'Curl con Mancuernas',
      muscleGroup: 'Bíceps',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 12,
    ),
    ExerciseCatalogEntry(
      id: 'ex_biceps_003',
      name: 'Curl en polea',
      muscleGroup: 'Bíceps',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 12,
    ),

    // ── Tríceps ───────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_triceps_001',
      name: 'Extensión de tríceps en polea',
      muscleGroup: 'Tríceps',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 12,
    ),
    ExerciseCatalogEntry(
      id: 'ex_triceps_002',
      name: 'Press francés',
      muscleGroup: 'Tríceps',
      equipment: 'Barra',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_triceps_003',
      name: 'Fondos en banco',
      muscleGroup: 'Tríceps',
      equipment: 'Peso corporal',
      defaultSets: 3,
      defaultReps: 12,
    ),

    // ── Piernas ───────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_piernas_001',
      name: 'Sentadilla',
      muscleGroup: 'Piernas',
      equipment: 'Barra',
      defaultSets: 4,
      defaultReps: 5,
    ),
    ExerciseCatalogEntry(
      id: 'ex_piernas_002',
      name: 'Prensa de Piernas',
      muscleGroup: 'Piernas',
      equipment: 'Máquina',
      defaultSets: 3,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_piernas_003',
      name: 'Extensión de Cuádriceps',
      muscleGroup: 'Piernas',
      equipment: 'Máquina',
      defaultSets: 3,
      defaultReps: 12,
    ),
    ExerciseCatalogEntry(
      id: 'ex_piernas_004',
      name: 'Curl de isquiotibiales',
      muscleGroup: 'Piernas',
      equipment: 'Máquina',
      defaultSets: 3,
      defaultReps: 12,
    ),
    ExerciseCatalogEntry(
      id: 'ex_piernas_005',
      name: 'Peso muerto rumano',
      muscleGroup: 'Piernas',
      equipment: 'Barra',
      defaultSets: 3,
      defaultReps: 8,
    ),
    ExerciseCatalogEntry(
      id: 'ex_piernas_006',
      name: 'Zancadas',
      muscleGroup: 'Piernas',
      equipment: 'Mancuernas',
      defaultSets: 3,
      defaultReps: 10,
    ),

    // ── Glúteos ───────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_gluteos_001',
      name: 'Hip thrust',
      muscleGroup: 'Glúteos',
      equipment: 'Barra',
      defaultSets: 4,
      defaultReps: 10,
    ),
    ExerciseCatalogEntry(
      id: 'ex_gluteos_002',
      name: 'Abducción de cadera',
      muscleGroup: 'Glúteos',
      equipment: 'Máquina',
      defaultSets: 3,
      defaultReps: 15,
    ),

    // ── Core ──────────────────────────────────────────────────────────
    ExerciseCatalogEntry(
      id: 'ex_core_001',
      name: 'Plancha',
      muscleGroup: 'Core',
      equipment: 'Peso corporal',
      defaultSets: 3,
      defaultReps: 1,
    ),
    ExerciseCatalogEntry(
      id: 'ex_core_002',
      name: 'Crunch en polea',
      muscleGroup: 'Core',
      equipment: 'Cable',
      defaultSets: 3,
      defaultReps: 15,
    ),
    ExerciseCatalogEntry(
      id: 'ex_core_003',
      name: 'Rueda abdominal',
      muscleGroup: 'Core',
      equipment: 'Peso corporal',
      defaultSets: 3,
      defaultReps: 10,
    ),
  ];

  /// Grupos musculares disponibles en orden de presentación.
  static const List<String> muscleGroups = [
    'Pecho',
    'Espalda',
    'Hombros',
    'Bíceps',
    'Tríceps',
    'Piernas',
    'Glúteos',
    'Core',
  ];

  /// Equipamiento disponible.
  static const List<String> equipmentTypes = [
    'Barra',
    'Mancuernas',
    'Máquina',
    'Cable',
    'Peso corporal',
  ];

  /// Filtra por grupo muscular.
  static List<ExerciseCatalogEntry> byMuscle(String muscleGroup) {
    return all.where((e) => e.muscleGroup == muscleGroup).toList();
  }

  /// Filtra por tipo de equipo.
  static List<ExerciseCatalogEntry> byEquipment(String equipment) {
    return all.where((e) => e.equipment == equipment).toList();
  }

  /// Búsqueda por nombre (insensible a mayúsculas).
  static List<ExerciseCatalogEntry> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return all
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.muscleGroup.toLowerCase().contains(q))
        .toList();
  }
}
