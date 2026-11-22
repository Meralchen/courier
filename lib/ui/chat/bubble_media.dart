import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../../telegram/voice_recorder.dart';

class BubbleMedia extends StatelessWidget {
  const BubbleMedia({
    super.key,
    required this.message,
    required this.outgoing,
    required this.onPhotoTap,
    this.onFileTap,
  });

  final Message message;
  final bool outgoing;
  final VoidCallback onPhotoTap;
  final VoidCallback? onFileTap;

  bool get _isImage =>
      message.kind == 'photo' ||
      message.kind == 'video' ||
      message.kind == 'animation' ||
      message.kind == 'sticker';

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final String path = store.pathFor(message.photoFileId, message.photoPath);

    if (message.kind == 'sticker') {
      if (path.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            message.text.isEmpty ? '🌟' : message.text,
            style: const TextStyle(fontSize: 44),
          ),
        );
      }
      // Animated stickers are gzipped Lottie (.tgs); Flutter cannot decode them
      // without a renderer, so show the sticker's emoji instead of an error.
      if (path.toLowerCase().endsWith('.tgs')) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            message.text.isEmpty ? '🌟' : message.text,
            style: const TextStyle(fontSize: 52),
          ),
        );
      }
      final double aspect = message.width > 0 && message.height > 0
          ? message.width / message.height
          : 1;
      final double side = 150;
      return GestureDetector(
        onTap: onPhotoTap,
        child: Image.file(
          File(path),
          width: aspect >= 1 ? side : side * aspect,
          height: aspect >= 1 ? side / aspect : side,
          fit: BoxFit.contain,
          errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Text(
            message.text.isEmpty ? '🌟' : message.text,
            style: const TextStyle(fontSize: 44),
          ),
        ),
      );
    }

    if (_isImage) {
      final bool photo = message.kind == 'photo';
      return GestureDetector(
        onTap: photo
            ? (path.isEmpty
                  ? () => store.ensureFile(message.photoFileId)
                  : onPhotoTap)
            : onFileTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 224,
            height: _height,
            child: path.isEmpty ? _placeholder(context, store) : _image(path),
          ),
        ),
      );
    }

    if (message.kind == 'voice' || message.kind == 'audio') {
      return _VoiceMessageRow(message: message, outgoing: outgoing);
    }

    if (message.kind == 'videoNote') {
      return GestureDetector(
        onTap: onFileTap,
        child: Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (outgoing ? Colors.white : colors.textPrimary).withValues(
              alpha: 0.10,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.videocam_outlined,
            size: 38,
            color: outgoing ? Colors.white70 : colors.textSecondary,
          ),
        ),
      );
    }

    if (message.kind == 'document' ||
        message.kind == 'video' ||
        message.kind == 'animation') {
      return GestureDetector(
        onTap: onFileTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: (outgoing ? Colors.white : colors.accent).withValues(
                  alpha: 0.18,
                ),
              ),
              child: Icon(
                message.kind == 'video'
                    ? Icons.play_circle_outline
                    : Icons.insert_drive_file_outlined,
                size: 20,
                color: outgoing ? Colors.white : colors.accent,
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    message.fileName.isEmpty ? 'Attachment' : message.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subhead.copyWith(
                      color: outgoing ? Colors.white : colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.fileSize > 0)
                    Text(
                      fileSizeLabel(message.fileSize),
                      style: AppText.caption.copyWith(
                        color: outgoing ? Colors.white70 : colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (message.kind == 'location') {
      return _simpleIcon(
        Icons.location_on_outlined,
        'Location',
        colors,
        outgoing,
      );
    }
    if (message.kind == 'contact') {
      return _simpleIcon(Icons.person_outline, 'Contact', colors, outgoing);
    }
    if (message.kind == 'poll') {
      return _simpleIcon(Icons.bar_chart, message.text, colors, outgoing);
    }
    if (message.kind == 'call') {
      return _simpleIcon(Icons.call, 'Call', colors, outgoing);
    }
    return const SizedBox.shrink();
  }

  double get _height {
    if (message.width <= 0 || message.height <= 0) return 168;
    final double ratio = message.width / message.height;
    return (224 / ratio.clamp(0.62, 1.9)).clamp(120, 300);
  }

  Widget _image(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
          const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white54),
          ),
    );
  }

  Widget _placeholder(BuildContext context, TelegramStore store) {
    final double progress = store.fileProgress[message.photoFileId] ?? 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (progress > 0)
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.download_rounded, color: Colors.white70, size: 26),
          const SizedBox(height: 6),
          Text(
            progress > 0 ? '${(progress * 100).round()}%' : 'Tap to load',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _simpleIcon(
    IconData icon,
    String label,
    AppColors colors,
    bool outgoing,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 19, color: outgoing ? Colors.white : colors.accent),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label.isEmpty ? 'Attachment' : label,
            style: AppText.subhead.copyWith(
              color: outgoing ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

}

/// Voice and audio messages play in place, like Telegram iOS: a play button,
/// the duration, and a thin progress line that advances while the native
/// player runs. Only one message plays at a time.
class _VoiceMessageRow extends StatefulWidget {
  const _VoiceMessageRow({required this.message, required this.outgoing});

  final Message message;
  final bool outgoing;

  @override
  State<_VoiceMessageRow> createState() => _VoiceMessageRowState();
}

class _VoiceMessageRowState extends State<_VoiceMessageRow> {
  static _VoiceMessageRowState? _active;

  Timer? _timer;
  bool _playing = false;
  bool _loading = false;
  int _position = 0;

  @override
  void dispose() {
    _timer?.cancel();
    if (identical(_active, this)) {
      _active = null;
      VoiceRecorder.stopPlayback();
    }
    super.dispose();
  }

  void _stopUi() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _position = 0;
    });
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle() async {
    if (_playing) {
      await VoiceRecorder.stopPlayback();
      if (identical(_active, this)) _active = null;
      _stopUi();
      return;
    }
    if (_loading) return;
    final TelegramStore store = TelegramScope.read(context);
    String path = store.pathFor(
      widget.message.mediaFileId,
      widget.message.mediaPath,
    );
    if (path.isEmpty) {
      if (widget.message.mediaFileId == 0) {
        _notice('This recording is not available.');
        return;
      }
      setState(() => _loading = true);
      await store.ensureFile(widget.message.mediaFileId);
      for (int attempt = 0; attempt < 100; attempt++) {
        path = store.pathFor(
          widget.message.mediaFileId,
          widget.message.mediaPath,
        );
        if (path.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (path.isEmpty) {
        _notice('The recording is still downloading.');
        return;
      }
    }
    if (!File(path).existsSync()) {
      _notice('The recording is no longer on this device.');
      return;
    }
    _active?._stopUi();
    try {
      await VoiceRecorder.play(path);
    } catch (error) {
      _notice('$error');
      return;
    }
    if (!mounted) return;
    _active = this;
    setState(() {
      _playing = true;
      _position = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int duration = widget.message.duration;
      if (duration > 0 && _position + 1 >= duration) {
        timer.cancel();
        VoiceRecorder.stopPlayback();
        if (identical(_active, this)) _active = null;
        setState(() {
          _playing = false;
          _position = 0;
        });
      } else {
        setState(() => _position++);
      }
    });
  }

  String _clock(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool outgoing = widget.outgoing;
    final Message message = widget.message;
    final Color foreground = outgoing ? Colors.white : colors.textPrimary;
    final Color secondary = outgoing ? Colors.white70 : colors.textSecondary;
    final int duration = message.duration;
    final String label = message.text.isEmpty
        ? (message.kind == 'voice' ? 'Voice message' : 'Audio')
        : message.text;
    final String timing = _playing || _position > 0
        ? '${_clock(_position)} / ${_clock(duration)}'
        : _clock(duration);

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 26,
            height: 26,
            child: _loading
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      outgoing ? Colors.white : colors.accent,
                    ),
                  )
                : Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: outgoing ? Colors.white : colors.accent,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subhead.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 104,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1.5),
                        child: LinearProgressIndicator(
                          value: duration > 0
                              ? (_position / duration).clamp(0.0, 1.0)
                              : 0,
                          minHeight: 2.5,
                          color: outgoing ? Colors.white : colors.accent,
                          backgroundColor: secondary.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      timing,
                      style: AppText.caption.copyWith(color: secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
