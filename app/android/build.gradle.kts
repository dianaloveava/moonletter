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
}
subprojects {
    // file_picker 的 android/build.gradle 用 `isAgp9OrAbove` 条件跳过 Kotlin 插件，
    // 而 Flutter 的 Gradle 插件是按正则扫脚本正文判断"插件是否已应用 KGP"的，
    // 于是它的 Kotlin 源码既不会被插件自己编译、也拿不到 Flutter 的兜底应用，
    // 最终 GeneratedPluginRegistrant 找不到 FilePickerPlugin。这里显式补上。
    if (name == "file_picker" && !plugins.hasPlugin("org.jetbrains.kotlin.android")) {
        pluginManager.apply("org.jetbrains.kotlin.android")
        // file_picker 也在同一个条件块里设置 kotlinOptions.jvmTarget = 17，
        // 这里缺了它 Kotlin 会跟随 Gradle 的 JDK（25），与 Java 侧 17 冲突。
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
