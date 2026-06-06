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

---

# Android Build Compatibility

## Síntoma

El build de Android falla en `assembleDebug` al correr `flutter run` o `flutter build apk`.

## Error típico

```
Execution failed for task ':file_picker:checkDebugAarMetadata'.
> Dependency ':flutter_plugin_android_lifecycle' requires libraries and applications
  that depend on it to compile against version 36 or later of the Android APIs.
  :file_picker is currently compiled against android-34.
```

## Causa raíz

Flutter 3.44.1 actualizó `flutter_plugin_android_lifecycle` a una versión que declara
en su AAR metadata que requiere `compileSdk ≥ 36`.

`file_picker 8.x` tiene `compileSdk 34` hardcodeado en su `build.gradle` propio,
lo que viola esa restricción en tiempo de build.

## Solución aplicada

En `android/build.gradle.kts` se agregó un override de `compileSdk = 36` para
todos los subproyectos de tipo `LibraryExtension` (plugins Flutter) mediante
`afterEvaluate`, dentro del bloque `subprojects{}` y antes de `evaluationDependsOn(":app")`.

```kotlin
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()
            ?.compileSdk = 36
    }
    project.evaluationDependsOn(":app")
}
```

Esto fuerza que todos los plugins (incluido `file_picker`) compilen con SDK 36
sin necesidad de modificar su código fuente.

## Advertencia para futuras actualizaciones

Si se actualiza `file_picker` a una versión que ya usa `flutter.compileSdkVersion`
(dinámico, como hace `file_picker 11.x`), hay que tener cuidado:

* `file_picker 11.x` tiene una API breaking: `FilePicker.platform` fue reemplazado
  por `FilePicker.pickFiles()` (método estático directo en clase `abstract final`).
* `file_picker 11.x` aplica Kotlin Gradle Plugin (KGP) directamente, lo que puede
  causar conflictos de compilación Kotlin→Java con Flutter 3.44.x.
* Verificar compatibilidad antes de actualizar:

```
flutter pub deps | grep file_picker
```

Probar el build en Android antes de commitear cualquier cambio de versión.

---

# En caso de duda

La fuente de verdad es:

1. AGENTS.md
2. ATLAS_MASTER_CONTEXT.md
3. BACKLOG ACTIVO

Nunca asumir que una tarea está completada sin verificar código y comportamiento.
