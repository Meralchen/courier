import 'package:flutter/services.dart';

/// Reads the chat a tapped notification asked to open. The native side keeps
/// the id from the launch intent until Flutter collects it, so a cold start and
/// a resume from the background both work the same way.
class NotificationLink {
  static const MethodChannel _channel = MethodChannel('courier/notifications');

  static Future<int> pendingChat() async {
    try {
      return await _channel.invokeMethod<int>('pendingChat') ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }
}
