# v1.7

Estado:

Importación de rutinas externas + edición completa de rutinas.

Logros:

* RoutineParser: motor texto libre → MockRoutine (detecta días, NxM, mapeo fuzzy contra ExerciseCatalog)
* ImportRoutineTextScreen: texto editable → parseo → vista previa → crear rutina
* ImportRoutinePdfScreen: PDF con texto seleccionable → extracción → parseo → vista previa → crear rutina
* ImportRoutineImageScreen: foto/galería → OCR con google_mlkit_text_recognition → texto editable → parseo → vista previa → crear rutina (mobile-first: Android + iOS; aviso en web)
* Fix RoutineParser: heurística de cabecera de día corregida — "Pullover en polea 3x12" ya no se detecta como día; regex añade `(\s|$)` tras keywords (push, pull, legs, etc.)
* EditRoutineScreen: pantalla completa de edición de rutinas

  * Renombrar rutina (inline en AppBar)
  * Duplicar rutina (menú ⋮)
  * Eliminar rutina con confirmación (menú ⋮)
  * Agregar / renombrar / eliminar días
  * Reordenar días con drag handle (ReorderableListView)
  * Agregar ejercicios (picker con búsqueda + filtros, reutilizado)
  * Eliminar ejercicios
  * Reordenar ejercicios con drag handle
  * Editar series × reps por ejercicio (diálogo inline)
  * Persistencia completa en Hive de todos los cambios
* RoutineStore ampliado: renameRoutine, duplicateRoutine, addDay, removeDay, renameDay, reorderDay, addExercise, removeExercise, reorderExercise, updateExercise
* Botones "Editar" en RoutinesScreen ahora navegan a EditRoutineScreen (antes mostraban "próximamente")

---

# v1.8

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

# v1.9

Estado:

PDFs escaneados con OCR automático — TAREA-019.

Logros:

* ImportRoutinePdfScreen soporta PDFs escaneados además de PDFs con texto
* Detección automática: si texto extraído < 40 chars → activa flujo OCR
* pdfx agregado para renderizar páginas PDF a imagen
* google_mlkit_text_recognition reutilizado para OCR página a página
* Nuevo _Phase.ocrProcessing para OCR de PDFs escaneados
* Nuevo _Phase.editing con texto OCR editable antes de parsear
* Web: muestra mensaje informativo — OCR solo disponible en móvil
* Badge "Texto extraído por OCR" visible en preview
* Archivos temporales eliminados automáticamente tras procesamiento
* PDFs escaneados soportados end-to-end
* 0 errores en flutter analyze

---

# v1.10

Estado:

Atlas Validator MVP + endurecimiento del parser.

Logros:

* Nuevo AtlasValidator
* Clasificación local:

  * validRoutine
  * trackingSheet
  * invalidText
* Integrado en importación por imagen
* Integrado en importación por PDF
* Bloquea planillas de seguimiento antes del parser
* Bloquea texto basura antes del parser
* routine_parser.dart ya no permite crear días vacíos
* Validado con pruebas reales:

  * "jj" → bloqueado
  * "123" → bloqueado
  * "SEMANA 4 / PIR / 10-8-6-4" → trackingSheet
  * Rutina con ejercicios NxM → importación correcta
