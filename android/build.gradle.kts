// Add repositories globally for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom build directories
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Task to clean the project
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Add necessary dependencies for the build system
buildscript {
    repositories {  // This part was missing
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.21")
        classpath("com.google.gms:google-services:4.3.15") // If using Firebase
    }
}
    