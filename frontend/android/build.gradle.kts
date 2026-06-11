allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

gradle.beforeProject {
    if ((name == "isar_flutter_libs" || name == "isar") && buildFile.exists()) {
        val content = buildFile.readText()
        if (!content.contains("namespace 'dev.isar")) {
            buildFile.appendText("\nandroid { namespace 'dev.isar.${name.replace("-", "_")}' }\n")
        }
        if (!content.contains("compileSdkVersion 34")) {
            buildFile.appendText("\nandroid { compileSdkVersion 34 }\n")
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
