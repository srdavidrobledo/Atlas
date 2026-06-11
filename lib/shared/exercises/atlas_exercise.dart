import 'exercise_categories.dart';

/// Modelo canónico de ejercicio en Atlas.
///
/// Diseñado para ser const y vivir en listas estáticas.
/// Compatible con OCR (aliases), generador de rutinas (difficulty, movement),
/// estadísticas (primaryMuscles) y Firebase futuro (id).
class AtlasExercise {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final Equipment equipment;
  final Difficulty difficulty;
  final MovementPattern movement;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String? instructions;
  final String? imageAsset;

  /// Variantes de nombre para matching fuzzy: OCR, importación de texto, búsqueda.
  /// Incluir nombres en español e inglés, con y sin tilde.
  final List<String> aliases;

  /// Objetivos de entrenamiento para los que este ejercicio es relevante.
  /// Usado por el generador de rutinas (ONB-002) para filtrar por goal del usuario.
  final List<TrainingGoal> trainingGoals;

  const AtlasExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.movement,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.instructions,
    this.imageAsset,
    this.aliases = const [],
    this.trainingGoals = const [],
  });

  /// Etiqueta de display compatible con el formato actual de la app: 'Pecho · Barra'.
  String get muscleLabel =>
      '${muscleGroup.displayName} · ${equipment.displayName}';

  /// Normaliza un string para matching: minúsculas, sin diacríticos, sin puntuación.
  /// Usado por ExerciseSearch y el pipeline OCR futuro.
  static String normalize(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
