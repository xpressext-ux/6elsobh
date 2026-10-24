import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Local fallback for this workspace: keep signing credentials outside the
// project files while still allowing a release build when key.properties is
// not present.
val localKeystoreFile = rootProject.file("../keystore/upload-key.jks")
val localKeystorePasswordFile = rootProject.file("../keystore/password.txt")
if (!keystorePropertiesFile.exists() && localKeystoreFile.exists() && localKeystorePasswordFile.exists()) {
    val localPassword = localKeystorePasswordFile.readText().trim()
    keystoreProperties["storeFile"] = localKeystoreFile.absolutePath
    keystoreProperties["storePassword"] = localPassword
    keystoreProperties["keyPassword"] = localPassword
    keystoreProperties["keyAlias"] = "upload"
}

// Prefer one-off environment variables for release signing so credentials are
// not persisted in the project workspace. Java Properties does not allow null
// values, so only write values that are actually available.
fun putSigningPropertyFromEnv(key: String, environmentKey: String) {
    if (!keystoreProperties.containsKey(key)) {
        System.getenv(environmentKey)?.takeIf { it.isNotBlank() }?.let {
            keystoreProperties[key] = it
        }
    }
}

putSigningPropertyFromEnv("storePassword", "ANDROID_KEYSTORE_PASSWORD")
putSigningPropertyFromEnv("keyPassword", "ANDROID_KEY_PASSWORD")
putSigningPropertyFromEnv("keyAlias", "ANDROID_KEY_ALIAS")
putSigningPropertyFromEnv("storeFile", "ANDROID_KEYSTORE_FILE")

android {
    namespace = "com.ammart.shop"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ammart.shop"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
    implementation("com.facebook.android:facebook-android-sdk:latest.release")
}
