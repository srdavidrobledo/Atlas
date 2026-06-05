# ATLAS RECOVERY GUIDE

Este documento explica cómo recuperar el proyecto Atlas desde cero.

Objetivo:

Que cualquier persona (o IA) pueda continuar el proyecto aunque:

* se pierda el chat
* cambie la computadora
* cambie la cuenta
* desaparezca el contexto previo

---

# Repositorio oficial

GitHub:

https://github.com/srdavidrobledo/Atlas

---

# Documentos importantes

Leer en este orden:

1. docs/ATLAS_MASTER_CONTEXT.md
2. AGENTS.md
3. docs/ATLAS_CHANGELOG.md

---

# Estado actual

Atlas se encuentra en v1.6.

MVP completo: persistencia, datos reales en todas las pantallas, insights automáticos.

Actualmente el foco está en:

TAREA-013 — Importación de rutinas externas (texto → rutina → OCR)

---

# Cómo preparar una PC nueva

## Instalar Git

Verificar:

git --version

---

## Instalar Flutter

Verificar:

flutter --version

---

## Instalar VS Code

Instalar extensiones:

* Flutter
* Dart

---

# Clonar Atlas

git clone https://github.com/srdavidrobledo/Atlas.git

---

# Obtener dependencias

flutter pub get

---

# Ejecutar Atlas

flutter run -d chrome --web-port=8080

Importante: usar siempre --web-port=8080 en Chrome.
IndexedDB (Hive web) es por origen. Sin puerto fijo, los datos no persisten entre reinicios.

---

# Validar entorno

flutter doctor

---

# Flujo de trabajo obligatorio

1. Leer AGENTS.md
2. Revisar BACKLOG ACTIVO
3. Verificar tareas pendientes
4. Trabajar en etapas pequeñas
5. Ejecutar flutter analyze
6. Esperar validación

---

# Reglas importantes

No modificar sin aprobación:

* router
* theme
* arquitectura general

---

# Componentes críticos

Mantener:

* WorkoutSessionStore
* ActiveWorkoutSession
* SessionExercise
* SessionSet
* SavedWorkoutSession

---

# Qué NO hacer

No implementar todavía:

* Firebase
* IA real
* Nutrición
* Notificaciones
* Tabata
* Reportes avanzados

---

# Próximo objetivo del proyecto

TAREA-013 — Importación de rutinas externas:

1. Fase 1: Motor texto libre → MockRoutine
2. Fase 2: OCR foto/PDF → texto
3. Fase 3: pipeline completo

Luego:

* editor de rutinas existentes
* Firebase / autenticación

---

# En caso de duda

La fuente de verdad es:

1. AGENTS.md
2. ATLAS_MASTER_CONTEXT.md
3. BACKLOG ACTIVO

Nunca asumir que una tarea está completada sin verificar código y comportamiento.
