import 'package:flutter/services.dart';

/// A document chosen through Android's own picker and copied into the app's
/// cache, ready for TDLib to upload.
class PickedDocument {
  const PickedDocument({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;
}

/// Thin client for the activity's `courier/files` channel.
class FilePickerChannel {
  static const MethodChannel _channel = MethodChannel('courier/files');

  /// Opens the system picker and returns null when the user cancels.
  static Future<PickedDocument?> pick() async {
    final Object? raw;
    try {
      raw = await _channel.invokeMethod<Object?>('pick');
    } on PlatformException catch (error) {
      throw Exception(error.message ?? 'Could not open the file picker');
    } on MissingPluginException {
      throw Exception('The file picker is unavailable on this device');
    }
    if (raw is! Map) return null;
    final String path = raw['path']?.toString() ?? '';
    if (path.isEmpty) return null;
    return PickedDocument(
      path: path,
      name: raw['name']?.toString() ?? 'File',
      size: (raw['size'] as num?)?.toInt() ?? 0,
    );
  }
}
