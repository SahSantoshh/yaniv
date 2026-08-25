# Keep annotations
-keepattributes *Annotation*

# (Optional) Keep your app entry points
-keep class com.sahsantoshh.yaniv.** { *; }

# WorkManager's Room database implementation is only reached via reflection,
# so R8 strips it under AGP 9, crashing at startup with:
# "Failed to create an instance of androidx.work.impl.WorkDatabase"
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
