# Courier release shrinker rules.
#
# TDLib's Java API is reached from native code through JNI, so the whole
# org.drinkless.tdlib package has to survive R8 untouched.
-keep class org.drinkless.tdlib.** { *; }
-dontwarn org.drinkless.tdlib.**

# Every class that declares a native method, and the methods themselves.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# The bridge classes are only referenced from Dart through method-channel
# names, so keep their members as well.
-keep class com.courier.messenger.telegram.** { *; }
-keep class com.courier.messenger.MainActivity { *; }

# Flutter's embedding is loaded reflectively by the engine.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
