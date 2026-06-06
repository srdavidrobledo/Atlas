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

# v1.4

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

---

# v1.5

Estado:

Dashboard y Progress con datos reales.

Logros:

* Dashboard reemplaza MockStats con _DashboardStats calculado desde WorkoutSessionStore.sessions
* Métricas reales: sesiones esta semana, horas este mes, total entrenamientos, último entreno
* ProgressScreen añade sección de 4 métricas resumen: sesiones, peso máx., duración media, tiempo total
* Progresión de fuerza con selector dinámico de ejercicios reales y % cambio entre sesiones
* Récords personales calculados desde ExerciseStat.maxKg (con fallback demo)

---

# v1.6

Estado:

Récords históricos y Atlas Coach Lite.

Logros:

* Detección de PR por sesión comparando cronológicamente contra máximos previos
* Badge 🏆 PR en tarjetas del historial cuando la sesión contiene un nuevo récord
* Sección "Mayor progreso histórico": ranking top-5 con barra visual y % de mejora
* AtlasCoach en lib/shared/atlas_coach.dart — motor de insights sin IA externa
* Sección "Atlas Coach" en Dashboard reemplaza Insights fijos
* 6 tipos de insight: días desde último entreno, frecuencia semanal, duración promedio, progreso reciente, mejor evolución histórica, motivacional por racha

Pendiente:

* TAREA-013 Importación de rutinas externas (activa)

---

# v1.7

Estado:

Limpieza arquitectural — TAREA-018.

Logros:

* Plataformas Flutter regeneradas: android/, ios/, web/
* test/widget_test.dart inicializado como placeholder
* exercise_catalog.dart movido: shared/ → features/routines/data/
* routine_parser.dart movido: shared/ → features/routines/data/
* 5 imports actualizados en screens de routines
* assets/images/ y assets/icons/ con placeholder .gitkeep
* 0 errores en flutter analyze (203 avisos info pre-existentes)

---

# v1.8

Estado:

PDFs escaneados con OCR automático — TAREA-019.

Logros:

* ImportRoutinePdfScreen soporta PDFs escaneados además de PDFs con texto
* Detección automática: si texto extraído < 40 chars → activa flujo OCR
* pdfx ^2.6.0 agregado para renderizar páginas PDF a imagen (JPEG, x2 resolución)
* google_mlkit_text_recognition reutilizado para OCR página a página
* Nuevo _Phase.ocrProcessing: spinner con "PDF escaneado detectado, aplicando OCR…"
* Nuevo _Phase.editing: texto OCR editable antes de parsear (igual que image_screen)
* _Phase.scanned eliminado (dead end reemplazado por flujo completo)
* Web: muestra mensaje informativo — OCR solo disponible en móvil
* Badge "Texto extraído por OCR" visible en preview
* Archivos temp de OCR eliminados automáticamente tras procesamiento
* _buildInfoBox() actualizado: ✅ PDFs escaneados soportados
* 0 errores en flutter analyze
