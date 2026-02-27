plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin HARUS terakhir
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tes_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.tes_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🔹 TAMBAHAN DARURAT (RINGAN & AMAN)
dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
}