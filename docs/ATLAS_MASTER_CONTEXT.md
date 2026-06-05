# ATLAS MASTER CONTEXT

## Resumen

Atlas es una aplicación Flutter orientada a entrenamiento físico, seguimiento de progreso y generación de rutinas.

El objetivo es evolucionar desde un prototipo funcional hacia un MVP completo de entrenamiento personal.

Repositorio:

https://github.com/srdavidrobledo/Atlas

---

# Estado actual del proyecto

## Infraestructura

Completado:

* Git configurado
* GitHub configurado
* Repositorio Atlas creado
* Flutter funcionando en PC personal
* Flutter funcionando en PC laboral
* VS Code configurado
* Codex configurado
* AGENTS.md creado y versionado

---

## Arquitectura

Tecnología:

* Flutter

Arquitectura:

* Feature First

Estructura principal:

lib/
├─ core/
├─ features/
├─ shared/

---

## Filosofía del proyecto

Atlas debe priorizar:

* simplicidad
* experiencia de entrenamiento
* velocidad de iteración
* mantenibilidad

Evitar complejidad innecesaria.

No incorporar infraestructura avanzada antes de validar funcionalidad.

---

## Tecnologías actualmente NO autorizadas

No implementar sin aprobación explícita:

* Firebase
* IA real
* Nutrición
* Fotos de comida
* Notificaciones
* Tabata
* Reportes avanzados

---

## Documento relacionado

Ver:

* AGENTS.md

para reglas de desarrollo y backlog.


---

# Historia del proyecto

## Origen

Atlas nació como una aplicación de entrenamiento personal desarrollada en Flutter.

La idea principal es construir una plataforma capaz de:

* gestionar rutinas
* registrar entrenamientos
* seguir progreso físico
* generar rutinas inteligentes
* convertirse en un asistente de entrenamiento personal

---

## Objetivo de negocio

Crear una aplicación propia con potencial comercial.

Atlas debe poder ser utilizada por:

* principiantes
* intermedios
* avanzados

La aplicación debe ayudar al usuario a:

* entrenar
* progresar
* registrar información
* mantener consistencia

---

# Decisiones importantes tomadas

## Decisión 001

Workout NO debe comenzar automáticamente.

Motivo:

El usuario debe tener control explícito del inicio del entrenamiento.

Flujo correcto:

Preparación
↓
Comenzar entrenamiento
↓
Entrenamiento activo

---

## Decisión 002

La sesión activa nunca debe perderse al cambiar de pestaña.

Motivo:

El usuario puede necesitar revisar progreso, rutinas o perfil durante el entrenamiento.

Comportamiento esperado:

Si existe una sesión activa:

"Tienes un entrenamiento en curso"

Opciones:

* Continuar entrenamiento
* Salir del entrenamiento

---

## Decisión 003

WorkoutSessionStore se mantiene como núcleo del sistema.

Motivo:

Evitar complejidad prematura.

Persistencia implementada con Hive (hive_flutter).
Firebase no reemplaza Hive hasta validar producto completo.

---

## Decisión 004

Atlas se desarrolla mediante iteraciones pequeñas.

Regla:

* cambios pequeños
* pruebas frecuentes
* validaciones manuales

Evitar modificaciones masivas.

---

## Decisión 005

Codex siempre debe trabajar guiado por backlog.

Motivo:

Se detectó que Codex podía completar tareas parciales y olvidar funcionalidades pendientes.

Por este motivo se creó:

BACKLOG ACTIVO

como fuente única de verdad.

---

# Lecciones aprendidas

## Lección 001

Antes de agregar nuevas funcionalidades:

verificar backlog.

---

## Lección 002

Antes de modificar una pantalla:

realizar auditoría del estado actual.

---

## Lección 003

Toda funcionalidad debe ser validada manualmente.

flutter analyze no garantiza que la UX sea correcta.

---

## Lección 004

La documentación del proyecto debe vivir dentro del repositorio.

No depender de conversaciones previas.

---

# Estado funcional actual

Última actualización:

Junio 2026 — v1.7

---

# Dashboard

Estado:

Funcional

## Implementado

* Header principal
* Objetivo actual
* Progreso de objetivo
* Logros recientes
* Próximo entrenamiento
* Insights

## Probado

Sí

## Observaciones

* Objetivo editable desde Perfil
* Logros recientes corregidos
* Overflow corregido

## Pendiente

* Mejorar visualmente progreso hacia objetivo

---

# Perfil

Estado:

Funcional

## Implementado

* Datos de usuario
* Objetivo editable

Opciones:

* Ganar músculo
* Perder grasa
* Fuerza
* Mantenimiento

## Probado

Sí

## Observaciones

Los cambios se reflejan correctamente en Dashboard.

---

# Progreso

Estado:

Funcional

## Implementado

* Semana
* Mes
* Año
* Peso corporal

## Probado

Sí

## Observaciones

Actualmente utiliza datos mock.

---

# Rutinas

Estado:

Funcional

## Implementado

* Lista de rutinas
* Visualización de días
* Selector de día sincronizado con WorkoutSessionStore
* Creación manual de rutinas (nombre, días, ejercicios)
* Catálogo de ejercicios con búsqueda por grupo muscular
* Selección múltiple y "seleccionar todos" en catálogo
* Activar / eliminar rutinas (no se puede eliminar la activa)
* Persistencia completa en Hive
* **Edición completa de rutinas (EditRoutineScreen):**
  * Renombrar rutina (inline en AppBar)
  * Duplicar rutina
  * Eliminar rutina con confirmación
  * Agregar / renombrar / eliminar días
  * Reordenar días con drag handle
  * Agregar ejercicios (picker con búsqueda y filtros)
  * Eliminar y reordenar ejercicios
  * Editar series × reps por ejercicio
* **Importación de rutinas:**
  * Texto libre → RoutineParser → vista previa → guardar
  * PDF con texto seleccionable → extraer → parsear → guardar
  * Foto / imagen → OCR (ML Kit, Android + iOS) → texto editable → parsear → guardar

## Probado

Sí

## Pendiente

Ninguno crítico.

---

# Entrenamiento

Estado:

Funcional

## Implementado

* WorkoutSessionStore

* ActiveWorkoutSession

* SessionExercise

* SessionSet

* SavedWorkoutSession

* Cronómetro

* Descanso configurable

* Peso editable

* Repeticiones editables

* RIR editable

* Estado:

  * Preparación
  * Entrenamiento activo
  * Descanso
  * Estoy listo
  * Resumen

## Probado

Sí

## Observaciones

Actualmente la pantalla está centrada en un ejercicio activo.

La arquitectura interna soporta múltiples ejercicios.

La representación visual todavía no refleja un día completo.

---

# Resumen de entrenamiento

Estado:

Funcional

## Implementado

* Duración real de sesión
* Series completadas
* Peso máximo levantado
* Mayor progreso vs historial previo
* Notas
* Estado emocional (feeling)

## Probado

Sí

## Observaciones

Datos 100% reales desde WorkoutSessionStore. Sin mock.

---

# Navegación

Estado:

Funcional

## Implementado

Protección de sesión activa.

Mensaje:

"Tienes un entrenamiento en curso"

Opciones:

* Continuar entrenamiento
* Salir del entrenamiento

## Probado

Sí

---

# Git

Estado:

Completado

## Implementado

* Git local
* GitHub
* Versionado

Repositorio:

https://github.com/srdavidrobledo/Atlas

## Probado

Sí

---

# Estado general del MVP

Completado:

* infraestructura
* navegación
* entrenamiento día completo
* objetivos
* creación manual de rutinas
* catálogo de ejercicios
* historial real
* persistencia local (Hive)
* dashboard con datos reales
* progress con datos reales
* récords históricos por ejercicio
* Atlas Coach Lite (insights automáticos sin IA)
* RoutineParser (texto libre → rutina)
* importación PDF
* importación por foto/OCR (Android + iOS, ML Kit)
* edición completa de rutinas (renombrar, duplicar, eliminar, días, ejercicios, sets/reps)

Pendiente:

* Firebase / autenticación (TAREA-018, no iniciar sin aprobación)
* Rutinas generadas por IA real (TAREA-019, depende de Firebase)

---

# Arquitectura técnica actual

## Organización general

Atlas utiliza arquitectura Feature First.

Estructura principal:

lib/
├─ core/
├─ features/
├─ shared/

---

# Core

Responsabilidad:

Infraestructura compartida.

Incluye:

* theme
* router
* constantes
* configuración global

Regla:

No modificar sin aprobación explícita.

---

# Shared

Responsabilidad:

Elementos reutilizables.

Incluye:

* widgets compartidos
* mock data
* componentes comunes

Ejemplos:

* atlas_bottom_nav
* atlas_widgets
* mock_data

---

# Features

Cada módulo funcional vive dentro de features.

---

## Dashboard

Responsabilidad:

Pantalla principal.

Muestra:

* objetivo actual
* progreso
* logros
* insights
* próximo entrenamiento

---

## Workout

Responsabilidad:

Gestión de sesiones de entrenamiento.

Actualmente es el núcleo del MVP.

---

### Componentes importantes

#### WorkoutSessionStore

Responsabilidad:

Mantener sesión activa.

Debe seguir siendo el centro del sistema.

No reemplazar sin aprobación.

---

#### ActiveWorkoutSession

Representa:

Entrenamiento activo en curso.

---

#### SessionExercise

Representa:

Ejercicio dentro de la sesión.

---

#### SessionSet

Representa:

Serie individual.

Incluye:

* peso
* repeticiones
* RIR
* completado

---

#### SavedWorkoutSession

Representa:

Resumen de sesión finalizada.

---

# Estado arquitectónico actual

La arquitectura ya soporta:

* múltiples ejercicios
* múltiples series
* sesión activa

La principal limitación actual es visual:

WorkoutScreen todavía representa un ejercicio activo en lugar de representar un día completo.

---

# Deuda técnica conocida

## DT-001

WorkoutScreen no representa todavía un día completo.

Estado: Resuelto (TAREA-006).

---

## DT-002

Nueva rutina no fue auditada completamente.

Estado: Resuelto (TAREA-008 + TAREA-009).

---

## DT-003

Selector de día necesita validación funcional completa.

Estado: Resuelto (TAREA-007).

---

## DT-004

Dashboard y ProgressScreen usan datos mock.

Estado: Resuelto (TAREA-014, TAREA-015, TAREA-016, TAREA-017).

---

## DT-005

No existe flujo de importación de rutinas externas.

Estado: Resuelto (TAREA-013).

---

## DT-006

Rutinas no eran editables tras crearlas.

Estado: Resuelto (TAREA-013D — EditRoutineScreen).

---

# Decisiones futuras

El MVP mobile está completo en funcionalidad core:

* entrenamiento
* rutinas (crear, editar, importar)
* historial y progreso reales
* insights automáticos

Antes de implementar Firebase o IA real:

1. Validar flujo completo en dispositivo físico Android / iOS
2. Completar TAREA-018 Firebase / autenticación
3. Luego TAREA-019 rutinas por IA

Target oficial: **Android ✅ iPhone ✅**. Web solo para desarrollo.
