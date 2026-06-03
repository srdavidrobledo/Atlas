# Atlas

Aplicación Flutter orientada a entrenamiento físico, seguimiento de progreso y generación de rutinas.

---

# Arquitectura

* Flutter
* Arquitectura feature-first

Estructura:

lib/
├─ core/
├─ features/
├─ shared/

---

# Modo de trabajo obligatorio para Atlas

Toda tarea debe dividirse en etapas numeradas.

Formato obligatorio:

ETAPA X/Y

Objetivo:

* ...

Archivos afectados:

* ...

Verificación:

* ...

---

Al finalizar cada etapa:

1. Ejecutar flutter analyze.
2. Informar:

   * errores
   * warnings
   * infos
3. Esperar aprobación.

No continuar automáticamente a la siguiente etapa.

---

Cada etapa debe ser:

* pequeña
* auditable
* reversible
* fácilmente testeable

Si una tarea requiere más de 5 archivos:

* dividirla en varias etapas

---

Siempre informar:

Progreso Atlas

Etapa actual:
X/Y

Porcentaje completado:
XX%

Próxima etapa:
...

---

# Registro obligatorio de tareas Atlas

Antes de comenzar cualquier implementación:

Mostrar siempre:

BACKLOG ACTIVO

Formato obligatorio:

[x] TAREA-001 Nombre
[ ] TAREA-002 Nombre

---

Reglas:

* Nunca eliminar tareas del backlog.
* Nunca asumir que una tarea está terminada.
* Una tarea sólo puede marcarse como completada [x] cuando:

  * la funcionalidad existe
  * flutter analyze no tiene errores
  * fue validada funcionalmente

---

Al inicio y final de cada respuesta informar:

Progreso Atlas

Completadas: X/Y
Pendientes: Y/X

Tareas completadas:

* ...

Tareas pendientes:

* ...

---

# BACKLOG ACTIVO

[x] TAREA-001 WorkoutSessionStore funcional

[x] TAREA-002 Cronómetro de entrenamiento

[x] TAREA-003 Descanso configurable

[x] TAREA-004 Objetivos editables

[x] TAREA-005 Protección al salir de una sesión activa

[ ] TAREA-006 Workout = día completo de entrenamiento

[ ] TAREA-007 Selección visual de día dentro de Workout

[ ] TAREA-008 Creación manual de rutinas

[ ] TAREA-009 Editor de rutinas

[ ] TAREA-010 Rutinas generadas por IA

[ ] TAREA-011 Persistencia local

[ ] TAREA-012 Historial real de entrenamientos

---

Prioridad actual:

1. TAREA-006 Workout = día completo
2. TAREA-008 Creación manual de rutinas
3. TAREA-009 Editor de rutinas
4. TAREA-010 Rutinas IA
5. TAREA-011 Persistencia local

---

# Reglas de trabajo

Antes de modificar código:

1. Analizar impacto.
2. Mostrar plan detallado.
3. Mostrar archivos afectados.
4. Esperar aprobación explícita.

No modificar código antes de aprobación.

---

# Restricciones

NO modificar sin aprobación:

* router
* theme
* estructura de navegación
* arquitectura general

---

# Calidad

Antes de finalizar cualquier tarea:

1. Ejecutar flutter analyze.
2. Informar:

   * errores
   * warnings
   * infos
3. Mostrar resumen de cambios.

---

# Workout

Mantener:

* WorkoutSessionStore
* ActiveWorkoutSession
* SessionExercise
* SessionSet
* SavedWorkoutSession

No reemplazar estas estructuras sin aprobación.

No reemplazar WorkoutSessionStore por:

* Firebase
* Hive
* Storage
* Repositories externos

sin aprobación explícita.

---

# Flujo UX obligatorio de entrenamiento

WorkoutScreen debe funcionar como:

Preparación
↓
Comenzar entrenamiento
↓
Entrenamiento activo
↓
Descanso
↓
Confirmación "Estoy listo"
↓
Siguiente serie
↓
Resumen

---

Reglas:

* Nunca iniciar automáticamente un entrenamiento al abrir WorkoutScreen.
* El usuario debe confirmar explícitamente el inicio.
* Si existe una sesión activa:

  * no eliminarla automáticamente
  * no reiniciarla automáticamente
  * permitir recuperarla

---

# Dashboard

Mantener diseño actual.

No rediseñar Dashboard sin aprobación.

---

# Rutinas

Priorizar:

* creación manual de rutinas
* edición de rutinas
* selección de días
* entrenamiento basado en día completo

---

# Entrenamiento

La pantalla Workout debe representar:

* un día completo de entrenamiento
* calentamiento
* fuerza
* accesorios
* core

No representar únicamente un ejercicio aislado.

Mantener:

* peso
* reps
* RIR
* descanso configurable
* cronómetro
* progreso de sesión

---

# Tecnologías NO autorizadas actualmente

No implementar:

* Firebase
* IA real
* Nutrición
* Fotos de comida
* Notificaciones
* Tabata
* Reportes avanzados
* Persistencia local permanente

sin aprobación explícita.

---

# Git

Trabajar siempre mediante cambios pequeños y auditables.

Evitar modificaciones masivas.

Preferir:

* cambios pequeños
* commits pequeños
* validaciones frecuentes

---

# Objetivo del proyecto

Convertir Atlas de prototipo funcional a MVP de entrenamiento personal.

Toda decisión técnica debe favorecer:

* claridad
* mantenibilidad
* velocidad de iteración
* facilidad para futuras integraciones

Antes de comenzar cualquier nueva funcionalidad:

Verificar el BACKLOG ACTIVO.

Si la tarea ya existe:

* continuarla

Si no existe:

* proponer agregarla al backlog antes de implementarla.

## Eficiencia de contexto

Antes de comenzar cualquier tarea:

1. Revisar BACKLOG.
2. Verificar si la tarea ya fue implementada.
3. Verificar si existe funcionalidad similar.
4. No reimplementar funcionalidades existentes.

Si una tarea fue completada:
marcarla como completada.

Si una tarea está parcialmente completada:
indicar porcentaje estimado.

Objetivo:
evitar trabajo duplicado y consumo innecesario de contexto.

## Auditoría obligatoria

Antes de comenzar cualquier tarea:

1. Revisar código existente.
2. Revisar backlog.
3. Revisar tareas completadas.
4. Revisar tareas parciales.

Nunca asumir que una tarea está pendiente.

Indicar:

- completado
- parcial
- pendiente

Objetivo:

Evitar implementar dos veces la misma funcionalidad.