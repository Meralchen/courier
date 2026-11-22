import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Telegram-iOS palette, light and dark.
@immutable
class AppColors {
  const AppColors({
    required this.dark,
    required this.background,
    required this.groupedBackground,
    required this.card,
    required this.cardElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.accent,
    required this.accentDeep,
    required this.bubbleIn,
    required this.bubbleOut,
    required this.onBubbleOut,
    required this.danger,
    required this.success,
    required this.glassTint,
    required this.chatBackdrop,
  });

  final bool dark;
  final Color background;
  final Color groupedBackground;
  final Color card;
  final Color cardElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;
  final Color accent;
  final Color accentDeep;
  final Color bubbleIn;
  final Color bubbleOut;
  final Color onBubbleOut;
  final Color danger;
  final Color success;
  final Color glassTint;
  final Color chatBackdrop;

  static const AppColors light = AppColors(
    dark: false,
    background: Color(0xFFFFFFFF),
    groupedBackground: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF7F7FA),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFFC7C7CC),
    separator: Color(0x1F000000),
    accent: Color(0xFF007AFF),
    accentDeep: Color(0xFF0A5FD6),
    bubbleIn: Color(0xFFFFFFFF),
    bubbleOut: Color(0xFF2FA6F2),
    onBubbleOut: Color(0xFFFFFFFF),
    danger: Color(0xFFFF3B30),
    success: Color(0xFF34C759),
    glassTint: Color(0x99FFFFFF),
    chatBackdrop: Color(0xFFDCE9F7),
  );

  static const AppColors darkMode = AppColors(
    dark: true,
    background: Color(0xFF000000),
    groupedBackground: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    cardElevated: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF98989F),
    textTertiary: Color(0xFF5C5C61),
    separator: Color(0x33FFFFFF),
    accent: Color(0xFF0A84FF),
    accentDeep: Color(0xFF0060DF),
    bubbleIn: Color(0xFF262628),
    bubbleOut: Color(0xFF0A84FF),
    onBubbleOut: Color(0xFFFFFFFF),
    danger: Color(0xFFFF453A),
    success: Color(0xFF30D158),
    glassTint: Color(0x661C1C1E),
    chatBackdrop: Color(0xFF0C1622),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkMode : light;
}

/// iOS type ramp in logical points.
abstract final class AppText {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );
  static const TextStyle title = TextStyle(
    fontSize: 17,
    height: 1.22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 1.29,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 1.28,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    height: 1.27,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

ThemeData buildTheme(AppColors c) {
  final ColorScheme scheme = ColorScheme(
    brightness: c.dark ? Brightness.dark : Brightness.light,
    primary: c.accent,
    onPrimary: Colors.white,
    secondary: c.accent,
    onSecondary: Colors.white,
    error: c.danger,
    onError: Colors.white,
    surface: c.background,
    onSurface: c.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: c.dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.separator,
    textTheme: const TextTheme().apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: c.dark ? Brightness.dark : Brightness.light,
      primaryColor: c.accent,
      scaffoldBackgroundColor: c.background,
    ),
  );
}
