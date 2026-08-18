# Flutter & AudioService
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# AndroidX Media & MediaSession
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class android.support.v4.media.session.** { *; }

# Prevent stripping notification action callbacks
-keepclassmembers class * extends androidx.media.MediaBrowserServiceCompat {
    public <methods>;
}
-keepclassmembers class * extends com.ryanheise.audioservice.AudioService {
    public <methods>;
}