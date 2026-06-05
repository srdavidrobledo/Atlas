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
Estado: Completado
Notas:
- Fase 1 ✅ RoutineParser: texto libre → MockRoutine, fuzzy matching contra ExerciseCatalog
- Fase 2a ✅ PDF con texto seleccionable → ImportRoutinePdfScreen
- Fase 2b ✅ OCR mobile-first con google_mlkit_text_recognition → ImportRoutineImageScreen (Android + iOS)
- Fase 2c ❌ PDFs escaneados / imágenes web (descartado: Atlas es mobile-first)
- Fase 3 ✅ Pipeline completo: imagen/PDF → texto → editable → parseo → vista previa → guardar

## TAREA-013D
Edición completa de rutinas
Estado: Completado
Notas:
- Renombrar / duplicar / eliminar rutina
- Agregar / renombrar / eliminar / reordenar días
- Agregar / eliminar / reordenar ejercicios
- Editar sets × reps inline
- Persistencia completa en Hive
- Fix parser: "Pullover en polea 3x12" ya no detectado como cabecera de día

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

## TAREA-018
Firebase / autenticación
Estado: Pendiente — no iniciar sin aprobación explícita
Dependencia: MVP mobile validado

## TAREA-019
Rutinas generadas por IA real
Estado: Pendiente — no iniciar sin aprobación explícita
Dependencia: Firebase / autenticación (TAREA-018)
