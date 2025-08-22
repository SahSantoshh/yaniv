# Keep all Flutter classes
-keep class io.flutter.** { *; }

# Keep all generated plugin classes
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*

# (Optional) Keep your app entry points
-keep class com.sahsantoshh.yaniv.** { *; }

# Keep all Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Keep Flutter deferred component classes
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
