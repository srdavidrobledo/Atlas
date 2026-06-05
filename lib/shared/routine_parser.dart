import 'exercise_catalog.dart';
import 'mock_data.dart';

// ─── Modelos de salida ────────────────────────────────────────────────────

class ParsedExercise {
  final String rawName;
  final int sets;
  final int reps;

  /// null → no hay coincidencia en ExerciseCatalog; se creará como ejercicio nuevo.
  final ExerciseCatalogEntry? catalogEntry;

  const ParsedExercise({
    required this.rawName,
    required this.sets,
    required this.reps,
    this.catalogEntry,
  });

  bool get isFromCatalog => catalogEntry != null;

  String get resolvedName => catalogEntry?.name ?? rawName;

  String get resolvedMuscle => catalogEntry != null
      ? '${catalogEntry!.muscleGroup} · ${catalogEntry!.equipment}'
      : 'Sin clasificar';

  MockExercise toMockExercise() => MockExercise(
        name: resolvedName,
        muscle: resolvedMuscle,
        sets: List.generate(
          sets,
          (_) => MockSet(kg: 0, reps: reps, rir: null, done: false),
        ),
        prevKg: 0,
        prevReps: reps,
      );
}

class ParsedDay {
  final String name;
  final List<ParsedExercise> exercises;
  const ParsedDay({required this.name, required this.exercises});
}

class ParsedRoutine {
  final String name;
  final List<ParsedDay> days;

  const ParsedRoutine({required this.name, required this.days});

  int get totalDays => days.length;
  int get totalExercises =>
      days.fold(0, (sum, d) => sum + d.exercises.length);
  int get matchedExercises =>
      days.fold(0, (sum, d) => sum + d.exercises.where((e) => e.isFromCatalog).length);

  /// Convierte a MockRoutine con el id dado.
  /// Los días y ejercicios quedan listos para añadir a MockData.routines.
  MockRoutine toMockRoutine(String routineId) {
    return MockRoutine(
      id: routineId,
      name: name,
      isActive: false,
      days: days.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        return MockRoutineDay(
          id: 'day_${routineId}_$i',
          name: d.name,
          exercises: d.exercises.map((e) => e.toMockExercise()).toList(),
        );
      }).toList(),
      totalSessions: 0,
      lastUsed: 'Nunca',
    );
  }
}

// ─── Parser ───────────────────────────────────────────────────────────────

class RoutineParser {
  /// Parsea texto libre y devuelve una [ParsedRoutine].
  ///
  /// Formatos soportados:
  ///   • "Nombre ejercicio 4x8"  o  "4x8 Nombre ejercicio"
  ///   • Separador NxM: x, X, ×  (ej. 4x8, 4 x 8, 4X8, 4×8)
  ///   • Cabeceras de día: Día A, Día 1, Push, Pull, Piernas, Lunes, …
  ///   • Sin cabecera: todo el texto se agrupa en un solo "Día 1"
  static ParsedRoutine parse(String text, {String? routineName}) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final days = <ParsedDay>[];
    String? currentDayName;
    var currentExercises = <ParsedExercise>[];

    void flushDay() {
      if (currentDayName != null) {
        days.add(ParsedDay(
          name: currentDayName,
          exercises: List.from(currentExercises),
        ));
      }
    }

    for (final line in lines) {
      if (_isDayHeader(line)) {
        flushDay();
        currentDayName = _cleanDayName(line);
        currentExercises = [];
      } else {
        final ex = _parseExerciseLine(line);
        if (ex != null) currentExercises.add(ex);
      }
    }
    flushDay();

    // Sin cabeceras de día → todo como "Día 1"
    if (days.isEmpty) {
      final exercises = lines
          .map(_parseExerciseLine)
          .whereType<ParsedExercise>()
          .toList();
      if (exercises.isNotEmpty) {
        days.add(ParsedDay(name: 'Día 1', exercises: exercises));
      }
    }

    return ParsedRoutine(
      name: routineName ?? 'Rutina importada',
      days: days,
    );
  }

  // ── Detección de cabecera de día ────────────────────────────────────────

  static final _dayKeywords = RegExp(
    r'^(día|dia|day|lunes|martes|mi[eé]rcoles|miercoles|jueves|viernes|'
    r's[aá]bado|sabado|domingo|push|pull|piernas|legs|upper|lower|'
    r'full\s*body|torso|empuje|tirón|tiron|fuerza|volumen)(\s|$)',
    caseSensitive: false,
  );

  static bool _isDayHeader(String line) {
    final norm = _normalize(line);
    if (_dayKeywords.hasMatch(norm)) return true;
    // Línea corta sin NxM y sin dígitos → probable cabecera libre ("Pecho y Tríceps")
    final hasNxM = _nxmRegex.hasMatch(line);
    if (!hasNxM && line.split(' ').length <= 4 && !RegExp(r'\d').hasMatch(line)) {
      return true;
    }
    return false;
  }

  static String _cleanDayName(String line) {
    // Normaliza capitalización básica
    return line.trim().isEmpty ? 'Día' : _capitalizeFirst(line.trim());
  }

  // ── Detección y parseo de ejercicio ────────────────────────────────────

  static final _nxmRegex = RegExp(r'(\d+)\s*[xX×]\s*(\d+)');

  static ParsedExercise? _parseExerciseLine(String line) {
    final match = _nxmRegex.firstMatch(line);
    if (match == null) return null;

    final sets = int.parse(match.group(1)!);
    final reps = int.parse(match.group(2)!);

    // Nombre: lo que esté antes o después del patrón NxM
    final before = line.substring(0, match.start).trim();
    final after = line.substring(match.end).trim();
    // Limpiar separadores comunes al inicio/fin
    final rawName = _cleanExerciseName(before.isNotEmpty ? before : after);

    if (rawName.isEmpty) return null;

    final entry = _findInCatalog(rawName);
    return ParsedExercise(
      rawName: rawName,
      sets: sets,
      reps: reps,
      catalogEntry: entry,
    );
  }

  static String _cleanExerciseName(String s) {
    return s
        .replaceAll(RegExp(r'^[-–—·:,\s]+'), '')
        .replaceAll(RegExp(r'[-–—·:,\s]+$'), '')
        .trim();
  }

  // ── Fuzzy matching contra ExerciseCatalog ──────────────────────────────

  static ExerciseCatalogEntry? _findInCatalog(String rawName) {
    final input = _normalize(rawName);

    // 1. Coincidencia exacta
    for (final e in ExerciseCatalog.all) {
      if (_normalize(e.name) == input) return e;
    }

    // 2. Coincidencia por substring (entrada contenida en catálogo o viceversa)
    for (final e in ExerciseCatalog.all) {
      final eName = _normalize(e.name);
      if (eName.contains(input) || input.contains(eName)) return e;
    }

    // 3. Solapamiento de palabras significativas (≥2 chars, ignora preposiciones)
    final inputWords = _significantWords(input);
    if (inputWords.isEmpty) return null;

    ExerciseCatalogEntry? best;
    int bestOverlap = 0;

    for (final e in ExerciseCatalog.all) {
      final eWords = _significantWords(_normalize(e.name));
      final overlap = inputWords.intersection(eWords).length;
      // Requiere al menos 1 palabra clave y al menos la mitad del input
      if (overlap > bestOverlap && overlap >= 1) {
        final threshold = (inputWords.length / 2).ceil();
        if (overlap >= threshold) {
          bestOverlap = overlap;
          best = e;
        }
      }
    }

    return best;
  }

  // ── Utilidades ─────────────────────────────────────────────────────────

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Set<String> _significantWords(String normalized) {
    const stopWords = {'de', 'con', 'en', 'el', 'la', 'los', 'las', 'y', 'a', 'al'};
    return normalized
        .split(' ')
        .where((w) => w.length >= 3 && !stopWords.contains(w))
        .toSet();
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
