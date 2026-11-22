import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';

class BubbleMedia extends StatelessWidget {
  const BubbleMedia({
    super.key,
    required this.message,
    required this.outgoing,
    required this.onPhotoTap,
  });

  final Message message;
  final bool outgoing;
  final VoidCallback onPhotoTap;

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
      return GestureDetector(
        onTap: onPhotoTap,
        child: Image.file(
          File(path),
          width: 132,
          height: 132,
          fit: BoxFit.contain,
          errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Text(
            message.text.isEmpty ? '🌟' : message.text,
            style: const TextStyle(fontSize: 44),
          ),
        ),
      );
    }

    if (_isImage) {
      return GestureDetector(
        onTap: path.isEmpty
            ? () => store.ensureFile(message.photoFileId)
            : onPhotoTap,
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            message.kind == 'voice' ? Icons.graphic_eq : Icons.play_arrow,
            color: outgoing ? Colors.white : colors.accent,
            size: 22,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text.isEmpty
                    ? (message.kind == 'voice' ? 'Voice message' : 'Audio')
                    : message.text,
                style: AppText.subhead.copyWith(
                  color: outgoing ? Colors.white : colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _duration(message.duration),
                style: AppText.caption.copyWith(
                  color: outgoing ? Colors.white70 : colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (message.kind == 'videoNote') {
      return Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (outgoing ? Colors.white : colors.textPrimary)
              .withValues(alpha: 0.10),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.videocam_outlined,
          size: 38,
          color: outgoing ? Colors.white70 : colors.textSecondary,
        ),
      );
    }

    if (message.kind == 'document' ||
        message.kind == 'video' ||
        message.kind == 'animation') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: (outgoing ? Colors.white : colors.accent)
                  .withValues(alpha: 0.18),
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
      );
    }

    if (message.kind == 'location') {
      return _simpleIcon(Icons.location_on_outlined, 'Location', colors, outgoing);
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
      errorBuilder: (BuildContext _, Object __, StackTrace? ___) => const Center(
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

  String _duration(int seconds) {
    if (seconds <= 0) return '';
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
