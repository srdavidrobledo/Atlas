import 'atlas_exercise.dart';
import 'atlas_exercise_library.dart';
import 'exercise_categories.dart';

/// Queries sobre AtlasExerciseLibrary.
///
/// Único punto de acceso para filtrado y matching.
/// Los consumidores (UI, OCR, generador de rutinas) no deben iterar
/// AtlasExerciseLibrary.all directamente.
class ExerciseSearch {
  const ExerciseSearch._();

  /// Busca por nombre o alias. Sin query devuelve todos.
  static List<AtlasExercise> byQuery(String query) {
    if (query.trim().isEmpty) return AtlasExerciseLibrary.all;
    final q = AtlasExercise.normalize(query);
    return AtlasExerciseLibrary.all.where((e) {
      if (AtlasExercise.normalize(e.name).contains(q)) return true;
      return e.aliases.any((a) => AtlasExercise.normalize(a).contains(q));
    }).toList();
  }

  /// Filtra por grupo muscular.
  static List<AtlasExercise> byMuscleGroup(MuscleGroup group) =>
      AtlasExerciseLibrary.all.where((e) => e.muscleGroup == group).toList();

  /// Filtra por equipamiento.
  static List<AtlasExercise> byEquipment(Equipment equipment) =>
      AtlasExerciseLibrary.all.where((e) => e.equipment == equipment).toList();

  /// Filtra por dificultad.
  static List<AtlasExercise> byDifficulty(Difficulty difficulty) =>
      AtlasExerciseLibrary.all.where((e) => e.difficulty == difficulty).toList();

  /// Filtra por patrón de movimiento.
  static List<AtlasExercise> byMovement(MovementPattern movement) =>
      AtlasExerciseLibrary.all.where((e) => e.movement == movement).toList();

  /// Filtra por objetivo de entrenamiento.
  static List<AtlasExercise> byGoal(TrainingGoal goal) =>
      AtlasExerciseLibrary.all.where((e) => e.trainingGoals.contains(goal)).toList();

  /// Filtro combinado. Pasar null para ignorar un criterio.
  static List<AtlasExercise> filter({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
    Difficulty? difficulty,
    MovementPattern? movement,
    TrainingGoal? goal,
  }) {
    var result = AtlasExerciseLibrary.all;
    if (goal != null) {
      result = result.where((e) => e.trainingGoals.contains(goal)).toList();
    }
    if (muscleGroup != null) {
      result = result.where((e) => e.muscleGroup == muscleGroup).toList();
    }
    if (equipment != null) {
      result = result.where((e) => e.equipment == equipment).toList();
    }
    if (difficulty != null) {
      result = result.where((e) => e.difficulty == difficulty).toList();
    }
    if (movement != null) {
      result = result.where((e) => e.movement == movement).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = AtlasExercise.normalize(query);
      result = result.where((e) {
        if (AtlasExercise.normalize(e.name).contains(q)) return true;
        return e.aliases.any((a) => AtlasExercise.normalize(a).contains(q));
      }).toList();
    }
    return result;
  }

  /// Matching fuzzy para OCR e importación de texto.
  ///
  /// Normaliza el texto de entrada y busca la mejor coincidencia entre
  /// nombre y aliases. Retorna null si el score no supera el umbral mínimo.
  static AtlasExercise? findBestMatch(String rawText) {
    final normalized = AtlasExercise.normalize(rawText);
    if (normalized.isEmpty) return null;

    AtlasExercise? best;
    int bestScore = 0;

    for (final e in AtlasExerciseLibrary.all) {
      final nameScore = _tokenScore(AtlasExercise.normalize(e.name), normalized);
      int aliasScore = 0;
      for (final a in e.aliases) {
        final s = _tokenScore(AtlasExercise.normalize(a), normalized);
        if (s > aliasScore) aliasScore = s;
      }
      final score = nameScore > aliasScore ? nameScore : aliasScore;
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }

    // Umbral: ≥60 para evitar falsos positivos en OCR
    return bestScore >= 60 ? best : null;
  }

  /// Score de similitud por tokens compartidos (Jaccard sobre palabras).
  static int _tokenScore(String a, String b) {
    final aTokens = a.split(' ').where((t) => t.length > 1).toSet();
    final bTokens = b.split(' ').where((t) => t.length > 1).toSet();
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    final shared = aTokens.intersection(bTokens).length;
    if (shared == 0) return 0;
    final union = aTokens.union(bTokens).length;
    return ((shared / union) * 100).round();
  }
}
