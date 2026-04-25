plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dhallah.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. تفعيل الـ Desugaring هنا
        isCoreLibraryDesugaringEnabled = true

        // 2. لعمل الإشعارات يفضل استخدام Java 8 أو 11 مع Desugaring
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // 3. تفعيل الـ MultiDex
        multiDexEnabled = true

        applicationId = "com.dhallah.app"
        minSdk = flutter.minSdkVersion // يفضل تحديده يدوياً بـ 21 على الأقل لدعم الإشعارات
        targetSdk = 36
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

// 4. إضافة قسم المكتبات (Dependencies) هنا في نهاية الملف
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
