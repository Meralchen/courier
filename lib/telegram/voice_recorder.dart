import 'package:flutter/services.dart';

/// One finished recording, ready to be sent as a TDLib voice note.
class VoiceClip {
  const VoiceClip({
    required this.path,
    required this.duration,
    required this.size,
  });

  factory VoiceClip.fromMap(Map<Object?, Object?> map) => VoiceClip(
    path: map['path']?.toString() ?? '',
    duration: (map['duration'] as num?)?.toInt() ?? 0,
    size: (map['size'] as num?)?.toInt() ?? 0,
  );

  final String path;
  final int duration;
  final int size;
}

class VoiceException implements Exception {
  VoiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Microphone recording through the activity's MediaRecorder channel.
///
/// The first [start] on Android opens the system permission dialog; the native
/// side holds the call until the user answers, so this future completes only
/// once recording has actually begun.
class VoiceRecorder {
  static const MethodChannel _channel = MethodChannel('courier/voice');

  static Future<String> start() async {
    try {
      final String? path = await _channel.invokeMethod<String>('start');
      if (path == null || path.isEmpty) {
        throw VoiceException('The recorder did not return a file');
      }
      return path;
    } on PlatformException catch (error) {
      throw VoiceException(error.message ?? 'Could not start recording');
    } on MissingPluginException {
      throw VoiceException('Voice recording is unavailable on this device');
    }
  }

  static Future<VoiceClip?> stop() async {
    try {
      final Map<Object?, Object?>? map = await _channel
          .invokeMethod<Map<Object?, Object?>>('stop');
      if (map == null) return null;
      final VoiceClip clip = VoiceClip.fromMap(map);
      return clip.path.isEmpty ? null : clip;
    } on PlatformException catch (error) {
      throw VoiceException(error.message ?? 'Could not finish recording');
    } on MissingPluginException {
      throw VoiceException('Voice recording is unavailable on this device');
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (_) {
      // Cancelling is best effort; a failed stop already discarded the file.
    }
  }

  /// Plays a downloaded voice note or audio file through the native player.
  static Future<void> play(String path) async {
    try {
      await _channel.invokeMethod<void>('play', <String, Object?>{
        'path': path,
      });
    } on PlatformException catch (error) {
      throw VoiceException(error.message ?? 'Could not play the recording');
    } on MissingPluginException {
      throw VoiceException('Playback is unavailable on this device');
    }
  }

  static Future<void> stopPlayback() async {
    try {
      await _channel.invokeMethod<void>('stopPlayback');
    } catch (_) {
      // Stopping a player that already finished is not an error.
    }
  }
}
