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

/// Rebuilds only when [select] returns a different value.
///
/// The store notifies for every TDLib update — typing, presence, each file
/// progress step. [TelegramScope.of] subscribes a whole screen to all of them;
/// this listens to the slice a widget actually draws, so a keystroke in one chat
/// no longer rebuilds the shell and the chat list behind it.
class StoreSelector<T> extends StatefulWidget {
  const StoreSelector({
    super.key,
    required this.select,
    required this.builder,
  });

  final T Function(TelegramStore store) select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<StoreSelector<T>> createState() => _StoreSelectorState<T>();
}

class _StoreSelectorState<T> extends State<StoreSelector<T>> {
  TelegramStore? _store;
  late T _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TelegramStore store = TelegramScope.read(context);
    if (identical(store, _store)) return;
    _store?.removeListener(_onChanged);
    _store = store..addListener(_onChanged);
    _value = widget.select(store);
  }

  void _onChanged() {
    final TelegramStore? store = _store;
    if (store == null || !mounted) return;
    final T next = widget.select(store);
    if (next == _value) return;
    setState(() => _value = next);
  }

  @override
  void dispose() {
    _store?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
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
