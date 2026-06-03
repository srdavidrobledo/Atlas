# Atlas

Aplicación Flutter orientada a entrenamiento físico, seguimiento de progreso y generación de rutinas.

## Arquitectura

- Flutter
- Arquitectura feature-first
- Estructura:

lib/
├─ core/
├─ features/
├─ shared/

## Reglas de trabajo

Antes de modificar código:

1. Analizar impacto.
2. Mostrar plan detallado.
3. Mostrar archivos afectados.
4. Esperar aprobación explícita.

## Restricciones

NO modificar sin aprobación:

- router
- theme
- estructura de navegación
- arquitectura general

## Calidad

Antes de finalizar cualquier tarea:

1. Ejecutar flutter analyze.
2. Informar errores, warnings e infos.
3. Mostrar resumen de cambios.

## Workout

Mantener:

- WorkoutSessionStore
- ActiveWorkoutSession
- SessionExercise
- SessionSet
- SavedWorkoutSession

No reemplazar WorkoutSessionStore por Firebase, Hive o Storage sin aprobación.

## Dashboard

Mantener diseño actual.

No rediseñar visualmente sin aprobación.

## Rutinas

Priorizar:

- creación manual de rutinas
- edición de rutinas
- selección de días
- entrenamiento basado en día completo

## Entrenamiento

La pantalla Workout debe representar:

- un día completo de entrenamiento
- calentamiento
- fuerza
- accesorios
- core

No representar únicamente un ejercicio aislado.

Mantener:

- peso
- reps
- RIR
- descanso configurable
- cronómetro
- progreso de sesión

## Tecnologías NO autorizadas actualmente

No implementar:

- Firebase
- IA real
- Nutrición
- Fotos de comida
- Notificaciones
- Tabata
- Reportes avanzados
- Persistencia local permanente

## Git

Trabajar siempre mediante cambios pequeños y auditables.

Evitar modificaciones masivas.

## Objetivo actual del proyecto

Convertir Atlas de prototipo funcional a MVP de entrenamiento personal.

Prioridad actual:

1. Workout = día completo
2. Editor de rutinas
3. Rutinas generadas por IA
4. Persistencia de datos