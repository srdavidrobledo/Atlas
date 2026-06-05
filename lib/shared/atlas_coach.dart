import '../features/workout/data/workout_session_store.dart';

class CoachInsight {
  final String emoji;
  final String body; // soporta **negrita** con _RichInsightText del dashboard
  const CoachInsight(this.emoji, this.body);
}

class AtlasCoach {
  static List<CoachInsight> generate(List<SavedWorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return [
        const CoachInsight(
          '💡',
          'Completa tu **primer entrenamiento** para ver insights personalizados.',
        ),
      ];
    }

    final now = DateTime.now();
    final insights = <CoachInsight>[];

    // 1. Días desde último entrenamiento
    final daysSince = now.difference(sessions.first.savedAt).inDays;
    if (daysSince == 0) {
      insights.add(const CoachInsight(
        '✅',
        '**Entrenaste hoy.** Descansa bien esta noche para maximizar la recuperación.',
      ));
    } else if (daysSince == 1) {
      insights.add(const CoachInsight(
        '💪',
        'Entrenaste **ayer**. Tu cuerpo está en recuperación activa.',
      ));
    } else if (daysSince <= 3) {
      insights.add(CoachInsight(
        '⚡',
        'Llevas **$daysSince días** sin entrenar. Buen momento para retomar.',
      ));
    } else {
      insights.add(CoachInsight(
        '🔔',
        'Han pasado **$daysSince días** desde tu último entrenamiento. ¡Es hora de volver!',
      ));
    }

    // 2. Frecuencia semanal (últimas 4 semanas)
    final weekStart4 = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1 + 21));
    final sessionsLast4Weeks =
        sessions.where((s) => !s.savedAt.isBefore(weekStart4)).length;
    final avgPerWeek = sessionsLast4Weeks / 4.0;
    if (avgPerWeek > 0) {
      insights.add(CoachInsight(
        '📅',
        'Promedio de **${avgPerWeek.toStringAsFixed(1)} sesiones por semana** en el último mes.',
      ));
    }

    // 3. Duración promedio
    final avgSecs =
        sessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ sessions.length;
    final avgMin = avgSecs ~/ 60;
    insights.add(CoachInsight(
      '⏱️',
      'Duración media de entrenamiento: **$avgMin minutos**.',
    ));

    // 4. Mayor progreso reciente — último highlight
    final highlight = sessions.first.highlight;
    if (highlight != null) {
      final imp = highlight.improvementPercent;
      if (imp == null) {
        insights.add(CoachInsight(
          '🏋️',
          'Primera vez registrando **${highlight.exerciseName}**: '
          '${highlight.currentKg.toStringAsFixed(1)} kg × ${highlight.currentReps} reps.',
        ));
      } else if (imp > 0) {
        insights.add(CoachInsight(
          '📈',
          'En tu último entreno mejoraste **${highlight.exerciseName}** '
          'un **+${imp.toStringAsFixed(1)}%** '
          '(${highlight.currentKg.toStringAsFixed(1)} kg × ${highlight.currentReps}).',
        ));
      }
    }

    // 5. Mejor evolución histórica
    final best = _bestHistoricalExercise(sessions);
    if (best != null) {
      insights.add(CoachInsight(
        '🏆',
        'Tu ejercicio con mayor progreso histórico es **${best.$1}** '
        'con un **+${best.$2.toStringAsFixed(1)}%** de mejora.',
      ));
    }

    // 6. Mensaje motivacional según racha
    final streak = _computeStreak(sessions, now);
    if (streak >= 8) {
      insights.add(CoachInsight(
        '🔥',
        '¡Llevas **$streak semanas consecutivas** entrenando! Estás en tu mejor racha.',
      ));
    } else if (streak >= 4) {
      insights.add(CoachInsight(
        '🔥',
        'Llevas **$streak semanas consecutivas**. ¡Consistencia igual a resultados!',
      ));
    } else if (streak >= 2) {
      insights.add(CoachInsight(
        '💡',
        'Llevas **$streak semanas seguidas**. La consistencia es la clave del progreso.',
      ));
    } else if (streak == 1 && sessions.length >= 2) {
      insights.add(const CoachInsight(
        '💡',
        'Entrena esta semana para **encadenar dos semanas consecutivas** y construir el hábito.',
      ));
    }

    return insights;
  }

  // Ejercicio con mayor % de mejora de primera a última aparición (requiere ≥2 sesiones)
  static (String, double)? _bestHistoricalExercise(
      List<SavedWorkoutSession> sessions) {
    final map = <String, List<double>>{};
    for (final s in sessions.reversed) {
      for (final e in s.exerciseStats) {
        if (e.maxKg <= 0) continue;
        map.putIfAbsent(e.name, () => []).add(e.maxKg);
      }
    }
    String? bestName;
    double bestPct = 0;
    for (final entry in map.entries) {
      if (entry.value.length < 2) continue;
      final first = entry.value.first;
      final max = entry.value.reduce((a, b) => a > b ? a : b);
      if (first <= 0) continue;
      final pct = (max - first) / first * 100;
      if (pct > bestPct) {
        bestPct = pct;
        bestName = entry.key;
      }
    }
    return bestName != null ? (bestName, bestPct) : null;
  }

  static int _computeStreak(List<SavedWorkoutSession> sessions, DateTime now) {
    int count = 0;
    for (var offset = 0; offset >= -52; offset--) {
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1 + (-offset * 7)));
      final sunday = monday.add(const Duration(days: 7));
      if (!sessions.any(
          (s) => !s.savedAt.isBefore(monday) && s.savedAt.isBefore(sunday))) {
        break;
      }
      count++;
    }
    return count;
  }
}
