import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (git-ignored). Release builds
// are never signed with debug keys: without the file, any release build
// (appbundle, apk, `flutter run --release`) fails with the message below.
// Debug builds don't need it.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val requiredKeystoreKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

// Returns why release signing can't work, or null when it can.
fun releaseSigningProblem(): String? {
    if (!keystorePropertiesFile.exists()) {
        return "android/key.properties is missing."
    }
    val missingKeys = requiredKeystoreKeys.filter {
        (keystoreProperties[it] as String?).isNullOrBlank()
    }
    if (missingKeys.isNotEmpty()) {
        return "android/key.properties is missing: ${missingKeys.joinToString()}."
    }
    val storeFile = file(keystoreProperties["storeFile"] as String)
    if (!storeFile.exists()) {
        return "The keystore named in android/key.properties (storeFile) was not found."
    }
    return null
}

val releaseSigningProblemMessage = releaseSigningProblem()

val checkReleaseSigning = tasks.register("checkReleaseSigning") {
    description = "Fails a release build that has no upload key configured."
    val problem = releaseSigningProblemMessage
    doLast {
        if (problem != null) {
            throw GradleException(
                "Release signing is not set up: $problem " +
                    "Release builds are never signed with debug keys. " +
                    "Create android/key.properties as described in README.md, " +
                    "section \"Release builds\"."
            )
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(checkReleaseSigning)
}

android {
    namespace = "com.elianfigueroa.vitamind"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.elianfigueroa.vitamind"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // No debug fallback. If the upload key isn't configured,
            // checkReleaseSigning stops the build before anything is signed.
            signingConfig = if (releaseSigningProblemMessage == null) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
