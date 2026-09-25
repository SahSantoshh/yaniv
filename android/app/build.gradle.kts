import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sahsantoshh.yaniv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.sahsantoshh.yaniv"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            // Only ABIs Flutter ships. Stops Play from serving empty splits
            // (e.g. x86) that crash with MissingLibraryException: libflutter.so.
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // AGP 8+ leaves .so files inside the APK (extractNativeLibs=false).
    // Flutter loads them via ReLinker, which often cannot see Play ABI
    // splits and crashes: "Could not find 'libflutter.so' ... only found: []".
    // Legacy packaging extracts libs to /data/app/.../lib so System.loadLibrary works.
    // NDK 28 keeps the extracted ELF 16 KB-aligned for Play's page-size requirement.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appNameSuffix"] = " (Debug)"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            manifestPlaceholders["appNameSuffix"] = ""
            manifestPlaceholders["admobAppId"] = "ca-app-pub-8062407442520576~6716644630"
            signingConfig = signingConfigs.getByName("release")
            // Enable code shrinking and resource shrinking
            isMinifyEnabled = true        // enables code shrinking (ProGuard/R8)
            isShrinkResources = true      // removes unused resources (images, strings, etc.)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

