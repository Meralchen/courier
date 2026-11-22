import 'dart:async';

import 'package:flutter/services.dart';

import 'models.dart';

class TelegramException implements Exception {
  TelegramException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper over the native channel. All Telegram semantics live in TDLib;
/// this class only moves maps across the platform boundary.
class TelegramClient {
  static const MethodChannel _methods = MethodChannel('courier/telegram');
  static const EventChannel _eventChannel =
      EventChannel('courier/telegram/events');

  Stream<Map<String, Object?>>? _events;

  Stream<Map<String, Object?>> get events =>
      _events ??= _eventChannel.receiveBroadcastStream().map(
            (Object? event) => asMap(event),
          );

  Future<void> call(String method, [Map<String, Object?> args = const {}]) async {
    try {
      await _methods.invokeMethod<void>(method, args);
    } on PlatformException catch (error) {
      throw TelegramException(error.message ?? 'Telegram error');
    } on MissingPluginException {
      throw TelegramException('The Telegram engine is unavailable on this device');
    }
  }

  Future<T?> invoke<T>(String method, [Map<String, Object?> args = const {}]) async {
    try {
      return await _methods.invokeMethod<T>(method, args);
    } on PlatformException catch (error) {
      throw TelegramException(error.message ?? 'Telegram error');
    } on MissingPluginException {
      throw TelegramException('The Telegram engine is unavailable on this device');
    }
  }
}
