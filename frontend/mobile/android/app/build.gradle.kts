import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Values come from android/key.properties (local, gitignored)
// or, when that file is absent, from environment variables (CI). See
// docs/lab06/01-signed-build.md for how the keystore is created and kept.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingValue(key: String, env: String): String? =
    keystoreProperties.getProperty(key) ?: System.getenv(env)

val releaseStoreFile = signingValue("storeFile", "FITFLOW_KEYSTORE_PATH")

android {
    namespace = "io.fitflow.fitflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Store identity. Kept separate from namespace so the Kotlin package never has to move.
        applicationId = "io.fitflow.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "FITFLOW_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "FITFLOW_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "FITFLOW_KEY_PASSWORD")
                storeType = "pkcs12"
            }
        }
    }

    buildTypes {
        release {
            // No fallback to the debug key (see the task-graph check below).
            signingConfig = signingConfigs.findByName("release")
            // R8: shrink, optimise and obfuscate Java/Kotlin code; drop unused resources.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Fail fast if a release artefact is requested without the upload key. A debug-signed
// bundle cannot be uploaded to Play and gives testers a build that can never be updated.
// Checked here rather than at configuration time so debug builds work without the key.
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { task ->
        task.project == project &&
            task.name.endsWith("Release") &&
            listOf("assemble", "bundle", "package").any { task.name.startsWith(it) }
    }
    if (wantsRelease && releaseStoreFile == null) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties " +
                "or set FITFLOW_KEYSTORE_PATH (see docs/lab06/01-signed-build.md).",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
