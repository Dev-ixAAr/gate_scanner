// ============================================================================
// gate_scanner — Android App Build Configuration
// ============================================================================

plugins {
    id "com.android.application"
    id "kotlin-android"
    // Flutter Gradle Plugin must be applied after Android and Kotlin plugins.
    id "dev.flutter.flutter-gradle-plugin"
}

// ----------------------------------------------------------------------------
// Keystore signing configuration.
// key.properties file is NOT committed to version control.
// It must be created manually on each build machine.
// See: android/key.properties.example for the required format.
// ----------------------------------------------------------------------------
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ------------------------------------------------------------------------
    // Namespace must match the applicationId.
    // Set during project creation via --org flag.
    // ------------------------------------------------------------------------
    namespace "com.yourcompany.gate_scanner"

    // ------------------------------------------------------------------------
    // compileSdkVersion: The Android API level used to compile the app.
    // Must be >= targetSdkVersion. Set to 34 (Android 14).
    // ------------------------------------------------------------------------
    compileSdkVersion 34

    // ------------------------------------------------------------------------
    // Kotlin JVM target configuration.
    // Required for compatibility with newer Kotlin/Java versions.
    // ------------------------------------------------------------------------
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        // Application ID — unique identifier for the app on the device and Play Store.
        // Must match the namespace above.
        applicationId "com.yourcompany.gate_scanner"

        // minSdkVersion: Minimum Android API level supported.
        // API 21 = Android 5.0 (Lollipop).
        // Covers ~99%+ of active Android devices.
        // Required by flutter_secure_storage and mobile_scanner.
        minSdkVersion 21

        // targetSdkVersion: The Android API level the app is designed for.
        // Set to 34 to comply with Google Play requirements (2024+).
        targetSdkVersion 34

        // versionCode: Integer version, incremented on each release.
        // Managed by Flutter via pubspec.yaml version field (the +build part).
        versionCode flutter.versionCode

        // versionName: Human-readable version string.
        // Managed by Flutter via pubspec.yaml version field (major.minor.patch part).
        versionName flutter.versionName

        // Enable multidex to support apps with more than 64K methods.
        // Required when using many packages.
        multiDexEnabled true
    }

    // ------------------------------------------------------------------------
    // Signing Configurations
    // Release signing uses key.properties file values.
    // Debug signing uses the default Flutter debug keystore automatically.
    // ------------------------------------------------------------------------
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        // --------------------------------------------------------------------
        // Release build:
        // - Signed with release keystore
        // - Code shrinking and resource shrinking enabled
        // - ProGuard/R8 optimization enabled
        // Use for: distribution, Play Store, production testing
        // --------------------------------------------------------------------
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }

        // --------------------------------------------------------------------
        // Debug build:
        // - Signed with default debug keystore (auto-generated)
        // - No code shrinking
        // - Debuggable flag enabled
        // Use for: local development, emulator testing, physical device testing
        // --------------------------------------------------------------------
        debug {
            // signingConfig signingConfigs.debug  // Flutter sets this automatically
            minifyEnabled false
            shrinkResources false
            debuggable true
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    // MultiDex support for API < 21 compatibility (required with multiDexEnabled)
    implementation 'androidx.multidex:multidex:2.0.1'
}