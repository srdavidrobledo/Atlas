# ATLAS BACKLOG

## TAREA-006
Workout = día completo
Estado: Completado
Prioridad: Alta

## TAREA-007
Selector de día funcional
Estado: Completado
Prioridad: Alta

## TAREA-008
Creación manual de rutinas
Estado: Completado
Prioridad: Alta

## TAREA-009
Editor de rutinas + catálogo de ejercicios
Estado: Completado
Notas: Catálogo con búsqueda por grupo muscular, selección múltiple, seleccionar todos.

## TAREA-010
Rutinas generadas por IA
Estado: Bloqueado
Dependencia:
- TAREA-006 ✅
- TAREA-008 ✅
- TAREA-009 ✅

## TAREA-011
Persistencia local con Hive
Estado: Completado
Notas:
- Rutinas del usuario (con días y ejercicios)
- Rutina activa y día activo
- Historial de sesiones completo
- Serialización JSON string (evita problemas de tipo en web)
- Regla de desarrollo: flutter run -d chrome --web-port=8080

## TAREA-012
Historial real
Estado: Completado
Notas: WorkoutSessionStore.sessions alimenta la pantalla de historial.

## TAREA-013
Importación de rutinas externas
Estado: Pendiente
Prioridad: Alta
Épica — no implementar hasta completar Dashboard y Progress reales.

Fases:
- Fase 1: Motor texto libre → MockRoutine (detectar días, ejercicios, sets/reps; mapear contra ExerciseCatalog; crear ejercicios nuevos si no existen en catálogo)
- Fase 2: OCR — foto o PDF → texto estructurado
- Fase 3: OCR → Motor de importación (pipeline completo)

## TAREA-014
Dashboard con datos reales
Estado: Pendiente
Prioridad: Alta
Notas: Reemplazar MockStats con WorkoutSessionStore.sessions.

## TAREA-015
ProgressScreen con datos reales
Estado: Pendiente
Prioridad: Alta
Notas: Gráficos fl_chart de volumen y peso por sesión.

## TAREA-016
Récords históricos por ejercicio
Estado: Pendiente
Prioridad: Alta
Notas: Máximo kg por ejercicio calculado a partir de ExerciseStat en sesiones guardadas.
