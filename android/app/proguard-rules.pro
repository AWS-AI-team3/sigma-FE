# MediaPipe
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Auto Value
-dontwarn javax.annotation.processing.**
-dontwarn javax.lang.model.**
-dontwarn com.google.auto.value.**

# Keep annotation processing classes
-keep class javax.annotation.processing.** { *; }
-keep class javax.lang.model.** { *; }
