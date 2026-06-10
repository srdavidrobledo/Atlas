enum RoutineTextType { validRoutine, trackingSheet, invalidText }

class AtlasValidator {
  static final _nxmRegex = RegExp(r'\d+\s*[xX×]\s*\d+');

  // Señales de planilla: columnas con kg repetidos, fechas, barras separadoras
  static final _trackingSignals = RegExp(
    r'(\d{1,3}[,.]?\d*\s*kg|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|'
    r'\d+\s*\|\s*\d+|\bsem(ana)?\s*\d|\brm\b|\b1rm\b)',
    caseSensitive: false,
  );

  static RoutineTextType classify(String text) {
    if (text.trim().length < 15) return RoutineTextType.invalidText;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final nxmCount = lines.where((l) => _nxmRegex.hasMatch(l)).length;
    final trackingCount = lines.where((l) => _trackingSignals.hasMatch(l)).length;

    // Sin ningún NxM → nunca es una rutina válida
    if (nxmCount == 0) {
      // Al menos 1 señal de tracking → planilla
      if (trackingCount >= 1) return RoutineTextType.trackingSheet;
      return RoutineTextType.invalidText;
    }

    // Planilla: más señales de tracking que líneas con ejercicios
    if (trackingCount > nxmCount * 2 && trackingCount >= 2) return RoutineTextType.trackingSheet;

    // Válida: al menos 1 NxM
    return RoutineTextType.validRoutine;
  }

  static String messageFor(RoutineTextType type) => switch (type) {
        RoutineTextType.trackingSheet =>
          'Esto parece una planilla de seguimiento (pesos/fechas). '
          'Pega el texto de tu programa de entrenamiento con el formato: Ejercicio 4×8.',
        RoutineTextType.invalidText =>
          'No se detectó ningún ejercicio. '
          'Usa el formato: "Press banca 4×8" por línea, con cabeceras de día opcionales.',
        RoutineTextType.validRoutine => '',
      };
}
