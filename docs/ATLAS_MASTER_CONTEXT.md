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
* Persistencia permanente

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

WorkoutSessionStore se mantiene como núcleo temporal del sistema.

Motivo:

Evitar complejidad prematura.

No reemplazar por:

* Firebase
* Hive
* Storage

hasta validar funcionalidad.

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

Junio 2026

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

Parcialmente funcional

## Implementado

* Lista de rutinas
* Visualización de días
* Selección básica de día

## Probado

Parcialmente

## Observaciones

Existe incertidumbre sobre el comportamiento real de selección de día.

Debe ser auditado nuevamente.

## Pendiente

* Creación manual de rutinas
* Editor de rutinas
* Validación completa del selector de día

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

* Duración
* Series
* Volumen
* Notas
* Estado emocional

## Probado

Sí

## Observaciones

Todavía utiliza parte de información mock.

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
* entrenamiento básico
* objetivos
* progreso

Pendiente:

* día completo de entrenamiento
* editor de rutinas
* generación IA
* persistencia real
* historial real
