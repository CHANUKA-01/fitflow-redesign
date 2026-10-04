# FitFlow release R8 rules.
# Flutter's Gradle plugin and each plugin (image_picker, url_launcher,
# shared_preferences, package_info_plus) ship their own consumer rules, so
# only app-specific rules belong here.

# Keep line numbers so Crashlytics stack traces stay readable after obfuscation.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter references Play Core deferred-component classes that this app does not use.
-dontwarn com.google.android.play.core.**
