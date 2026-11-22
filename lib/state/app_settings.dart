import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only preferences. Everything account-related stays in TDLib.
class AppSettings extends ChangeNotifier {
  static const String _themeKey = 'courier.theme';
  static const String _notificationsKey = 'courier.notifications';
  static const String _soundsKey = 'courier.sounds';

  ThemeMode themeMode = ThemeMode.system;
  bool notifications = true;
  bool sounds = true;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifications = prefs.getBool(_notificationsKey) ?? true;
    sounds = prefs.getBool(_soundsKey) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
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
}
