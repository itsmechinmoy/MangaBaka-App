# Keep Flutter's embedding and generated plugin wiring intact.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dev.oazzies.mangabaka_app.MainActivity { *; }

# Android/Google libraries used by Flutter plugins.
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
