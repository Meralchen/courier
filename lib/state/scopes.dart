import 'package:flutter/widgets.dart';

import 'app_settings.dart';
import '../telegram/telegram_store.dart';

class TelegramScope extends InheritedNotifier<TelegramStore> {
  const TelegramScope({
    super.key,
    required TelegramStore store,
    required super.child,
  }) : super(notifier: store);

  static TelegramStore of(BuildContext context) {
    final TelegramScope? scope =
        context.dependOnInheritedWidgetOfExactType<TelegramScope>();
    assert(scope != null, 'TelegramScope is missing above this widget');
    return scope!.notifier!;
  }

  /// Reads the store without subscribing; for callbacks.
  static TelegramStore read(BuildContext context) {
    final TelegramScope? scope =
        context.getInheritedWidgetOfExactType<TelegramScope>();
    assert(scope != null, 'TelegramScope is missing above this widget');
    return scope!.notifier!;
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final SettingsScope? scope =
        context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope is missing above this widget');
    return scope!.notifier!;
  }
}
