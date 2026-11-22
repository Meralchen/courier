plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.courier.messenger"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.courier.messenger"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // No owner keystore is stored in this repository. A debug-key-signed
            // release APK is installable everywhere and is what "stable" means
            // here; swap in a real keystore for store distribution.
            signingConfig = signingConfigs.getByName("debug")
            // Commercial Telegram clients ship R8-shrunk; only TDLib's JNI
            // surface and the bridge need explicit keeps (proguard-rules.pro).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    lint {
        // AGP 9.3.1's lint crashes while parsing JavaDoc on this toolchain
        // (NoSuchMethodError: JavaDocParser.parseDataItem). Dart analysis still
        // runs in CI; APK assembly must not depend on the broken lint task.
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("io.github.tdlib-android:core:0.1.1")
}

flutter {
    source = "../.."
}
