import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/wallpaper.dart';

/// How the material is drawn. `liquid` runs the liquiglass shader and the
/// colour backdrop; `classic` is the flat iOS 13–18 look with opaque bars.
enum GlassStyle { liquid, classic }

/// Local-only preferences. Everything account-related stays in TDLib.
class AppSettings extends ChangeNotifier {
  static const String _themeKey = 'courier.theme';
  static const String _glassKey = 'courier.glass';
  static const String _notificationsKey = 'courier.notifications';
  static const String _soundsKey = 'courier.sounds';
  static const String _wallpaperKey = 'courier.wallpaper';
  static const String _energyKey = 'courier.energy';

  ThemeMode themeMode = ThemeMode.system;
  GlassStyle glassStyle = GlassStyle.liquid;
  bool notifications = true;
  bool sounds = true;
  ChatWallpaper wallpaper = ChatWallpaper.doodle;

  /// Energy Saver drops the liquid material and animated effects, the way
  /// Telegram-iOS disables its heavier visuals.
  bool energySaving = false;

  /// Material actually in use: Energy Saver falls back to Classic iOS.
  bool get liquid => glassStyle == GlassStyle.liquid && !energySaving;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    glassStyle = prefs.getString(_glassKey) == 'classic'
        ? GlassStyle.classic
        : GlassStyle.liquid;
    notifications = prefs.getBool(_notificationsKey) ?? true;
    sounds = prefs.getBool(_soundsKey) ?? true;
    wallpaper = switch (prefs.getString(_wallpaperKey)) {
      'gradient' => ChatWallpaper.gradient,
      'plain' => ChatWallpaper.plain,
      _ => ChatWallpaper.doodle,
    };
    energySaving = prefs.getBool(_energyKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setGlassStyle(GlassStyle style) async {
    if (glassStyle == style) return;
    glassStyle = style;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_glassKey, style.name);
  }

  Future<void> setNotifications(bool value) async {
    notifications = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> setSounds(bool value) async {
    sounds = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundsKey, value);
  }

  Future<void> setWallpaper(ChatWallpaper value) async {
    if (wallpaper == value) return;
    wallpaper = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperKey, value.name);
  }

  Future<void> setEnergySaving(bool value) async {
    if (energySaving == value) return;
    energySaving = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_energyKey, value);
  }
}
