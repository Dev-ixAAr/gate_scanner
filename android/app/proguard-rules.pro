# ============================================================================
# gate_scanner — ProGuard / R8 Rules
# Applied during release builds when minifyEnabled = true
# ============================================================================

# ----------------------------------------------------------------------------
# Flutter
# Keep Flutter engine classes from being obfuscated
# ----------------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ----------------------------------------------------------------------------
# Kotlin
# ----------------------------------------------------------------------------
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ----------------------------------------------------------------------------
# Dio / OkHttp networking
# Required to prevent R8 from removing networking classes
# ----------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ----------------------------------------------------------------------------
# flutter_secure_storage
# Prevent Android Keystore related classes from being stripped
# ----------------------------------------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ----------------------------------------------------------------------------
# mobile_scanner / CameraX
# ----------------------------------------------------------------------------
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ----------------------------------------------------------------------------
# Gson / JSON serialization
# Keep model classes with @SerializedName annotations
# ----------------------------------------------------------------------------
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ----------------------------------------------------------------------------
# General: Keep line numbers for crash reporting stack traces
# ----------------------------------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile