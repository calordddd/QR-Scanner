# Keep CameraX classes required by mobile_scanner
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Keep Google ML Kit / Play Services barcode scanning
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_barcode_bundled.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode_bundled.**

# Keep mobile_scanner plugin classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**

# Keep Flutter plugin registrant
-keep class io.flutter.plugins.** { *; }
