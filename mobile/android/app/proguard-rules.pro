# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift Database
-keep class * extends dev.drift.runtime.database.** { *; }
-keep class * extends dev.drift.runtime.database.**$* { *; }
-keepclassmembers class * extends dev.drift.runtime.database.** {
    *;
}

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Dio
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep model classes
-keep class million.halal.mart.** { *; }

# Google Play Core library klasslarini saqlab qolish
-keep class com.google.android.play.core.** { *; }

# Flutter ning deferred components klasslarini saqlab qolish
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Agar xatolikda ko'rsatilgan konkret klasslar bo'lsa:
-dontwarn com.google.android.play.core.**

-ignorewarnings
-keepattributes *Annotation*


