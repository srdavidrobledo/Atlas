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
Estado: Activa — siguiente tarea
Prioridad: Alta

Fases:
- Fase 1: Motor texto libre → MockRoutine (detectar días, ejercicios, sets/reps; mapear contra ExerciseCatalog; crear ejercicios nuevos si no existen en catálogo)
- Fase 2: OCR — foto o PDF → texto estructurado
- Fase 3: OCR → Motor de importación (pipeline completo)

## TAREA-014
Dashboard con datos reales
Estado: Completado
Notas: _DashboardStats reemplaza MockStats. Métricas: sesiones esta semana, horas este mes, logros, último entreno.

## TAREA-015
ProgressScreen con datos reales
Estado: Completado
Notas: _ProgressStats cubre 4 métricas resumen, progresión de fuerza real por ejercicio, récords desde ExerciseStat.

## TAREA-016
Récords históricos por ejercicio
Estado: Completado
Notas: PR detection cronológica, badge 🏆 en historial, ranking "Mayor progreso histórico" con barra visual y % de mejora.

## TAREA-017
Atlas Coach Lite
Estado: Completado
Notas: AtlasCoach en lib/shared/ genera hasta 6 insights dinámicos: días desde último entreno, frecuencia semanal, duración promedio, progreso reciente (highlight), mejor evolución histórica, motivacional por racha. Sin IA externa.
