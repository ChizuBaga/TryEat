import java.io.FileInputStream
import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.huawei.agconnect") 
}

dependencies {
    implementation("com.huawei.agconnect:agconnect-core:1.5.2.300")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.chikankan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    lint {
        disable += "MissingNamespace"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

   packagingOptions {
    jniLibs {
        useLegacyPackaging = true
        // Use .addAll() with listOf() and double quotes
        keepDebugSymbols.addAll(listOf("*/arm64-v8a/*.so", "*/armeabi-v7a/*.so"))
    }
    // Use parentheses and double quotes
    pickFirst("lib/arm64-v8a/libmap.so")
    pickFirst("lib/armeabi-v7a/libmap.so")
}

    
    defaultConfig {
    applicationId = "eatseesee.huawei"
    minSdk = 23
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    ndk {
        // Use addAll() with listOf() and double quotes
        abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
    }
    //Add for push kit 
    resConfigs("en", "zh-rCN")
}
    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = File(rootProject.file(keystoreProperties.getProperty("storeFile")!!).toURI())
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        // Line 56 - 60 (Corrected Release block)
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            
            // Standard release config
            isMinifyEnabled = true 
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        // Keep the debug block as is (or simplify it)
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

repositories {
    google()
    mavenCentral()
    maven(url = "https://developer.huawei.com/repo/")
}
