# ATLAS CHANGELOG

Este documento registra la evolución histórica del proyecto.

---

# v0.1

Estado:

Inicio del proyecto.

Logros:

* Creación del proyecto Flutter.
* Estructura inicial.
* Definición del concepto Atlas.

---

# v0.2

Estado:

Arquitectura inicial.

Logros:

* Arquitectura Feature First.
* Organización:

  * core
  * features
  * shared

---

# v0.3

Estado:

Primer MVP navegable.

Logros:

* Dashboard
* Workout
* Progress
* Profile
* Rutinas

---

# v0.4

Estado:

Sistema de entrenamiento.

Logros:

* WorkoutSessionStore
* ActiveWorkoutSession
* SessionExercise
* SessionSet
* SavedWorkoutSession

---

# v0.5

Estado:

Entrenamiento funcional.

Logros:

* Cronómetro
* Descanso configurable
* Peso editable
* Repeticiones editables
* RIR editable

---

# v0.6

Estado:

Control de sesión.

Logros:

* Confirmación manual para iniciar entrenamiento
* Estado Preparación
* Estado Entrenamiento activo
* Estado Descanso
* Estado Estoy listo

Decisión importante:

El entrenamiento NO inicia automáticamente.

---

# v0.7

Estado:

Protección de navegación.

Logros:

* Detección de sesión activa
* Confirmación al abandonar entrenamiento

Mensaje:

"Tienes un entrenamiento en curso"

Opciones:

* Continuar entrenamiento
* Salir del entrenamiento

---

# v0.8

Estado:

Perfil y objetivos.

Logros:

Objetivos editables:

* Ganar músculo
* Perder grasa
* Fuerza
* Mantenimiento

---

# v0.9

Estado:

Estabilización visual.

Logros:

* Corrección de overflow
* Ajustes Dashboard
* Ajustes Workout

---

# v1.0

Estado:

MVP funcional.

Completado:

* Infraestructura
* Git / GitHub / Flutter
* Dashboard, Workout, Progress, Profile, Rutinas básicas

---

# v1.1

Estado:

Workout día completo + selector de día.

Logros:

* WorkoutScreen con todos los ejercicios del día activo
* Selector visual de día (tabs en WorkoutScreen)
* Sincronización día activo ↔ WorkoutSessionStore
* Cronómetro, RIR, peso y reps editables por set

---

# v1.2

Estado:

Creación manual de rutinas + catálogo de ejercicios.

Logros:

* CreateRoutineScreen: nombre, días, ejercicios por día
* ExerciseCatalog: búsqueda por grupo muscular
* Selección múltiple y "seleccionar todos"
* RoutineStore: gestión de rutinas en memoria
* Activar / eliminar rutinas desde RoutinesScreen

---

# v1.3

Estado:

Historial real + Workout Summary con datos reales.

Logros:

* WorkoutSummaryScreen con datos reales de sesión
* Peso máximo levantado reemplaza volumen en resumen
* Mayor progreso calculado comparando contra historial
* Historial de sesiones alimentado por WorkoutSessionStore.sessions
* Feeling y notas guardados por sesión

---

# v1.4 (Actual)

Estado:

Persistencia local validada.

Logros:

* Persistencia con Hive (hive_flutter)
* Serialización JSON string (evita problemas de tipo anidado en web)
* Rutinas del usuario con días y ejercicios persisten entre sesiones
* Rutina activa y día activo persisten entre sesiones
* Historial de sesiones persiste entre sesiones
* Writes correctamente awaited (Future<void>)
* Validado en Chrome con --web-port=8080

Pendiente:

* TAREA-014 Dashboard con datos reales
* TAREA-015 ProgressScreen con datos reales
* TAREA-016 Récords históricos por ejercicio
* TAREA-013 Importación de rutinas externas (épica futura)
