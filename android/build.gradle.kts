allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // ── Workaround: compileSdk 36 para plugins legacy ────────────────────────
    // Contexto: Flutter 3.44.1 actualizó flutter_plugin_android_lifecycle a una
    // versión que declara en su AAR metadata: "requiero compileSdk ≥ 36".
    // Cualquier plugin que dependa de él debe compilar con SDK 36 o superior.
    //
    // Problema: file_picker 8.x (y otras librerías que aún no se actualizaron)
    // tiene compileSdk 34 hardcodeado en su propio build.gradle, por lo que
    // el task :file_picker:checkDebugAarMetadata falla en build time con:
    //   "Dependency ':flutter_plugin_android_lifecycle' requires compileSdk ≥ 36.
    //    :file_picker is currently compiled against android-34."
    //
    // Solución: forzar compileSdk = 36 en todos los subproyectos de tipo
    // LibraryExtension (plugins Flutter) vía afterEvaluate.
    //
    // Nota técnica: afterEvaluate se registra ANTES de evaluationDependsOn(":app")
    // dentro del mismo bloque subprojects{} para evitar el error de Gradle:
    //   "Cannot run Project.afterEvaluate when the project is already evaluated."
    //
    // Cuando actualizar: si file_picker 9.x+ o cualquier otro plugin migra a
    // flutter.compileSdkVersion (dinámico), este override se vuelve redundante
    // para ese plugin, pero no genera conflicto al mantenerlo.
    // Verificar con: flutter pub deps | grep file_picker
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()
            ?.compileSdk = 36
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
