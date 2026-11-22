import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.title,
    required this.seed,
    this.size = 54,
    this.photoFileId = 0,
    this.photoPath = '',
    this.online = false,
    this.showOnline = false,
    this.square = false,
    this.badge,
  });

  final String title;
  final int seed;
  final double size;
  final int photoFileId;
  final String photoPath;
  final bool online;
  final bool showOnline;
  final bool square;
  final Widget? badge;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _maybeDownload();
  }

  @override
  void didUpdateWidget(covariant Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeDownload();
  }

  void _maybeDownload() {
    if (_requested || widget.photoFileId == 0) return;
    final String path = widget.photoPath.isNotEmpty
        ? widget.photoPath
        : TelegramScope.read(context).filePaths[widget.photoFileId] ?? '';
    if (path.isNotEmpty) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TelegramScope.read(context).ensureFile(widget.photoFileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String path = widget.photoPath.isNotEmpty
        ? widget.photoPath
        : TelegramScope.of(context).filePaths[widget.photoFileId] ?? '';
    final List<Color> gradient = avatarGradient(widget.seed);
    final BorderRadius radius =
        BorderRadius.circular(widget.square ? widget.size * 0.30 : widget.size);

    final Widget fallback = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(widget.title),
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.34,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    );

    final Widget image = path.isEmpty
        ? fallback
        : ClipRRect(
            borderRadius: radius,
            child: Image.file(
              File(path),
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                  fallback,
            ),
          );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 0.7,
              ),
            ),
            child: image,
          ),
          if (widget.showOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: widget.size * 0.28,
                height: widget.size * 0.28,
                decoration: BoxDecoration(
                  color: widget.online ? colors.success : colors.textTertiary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.background,
                    width: widget.size * 0.055,
                  ),
                ),
              ),
            ),
          if (widget.badge != null) widget.badge!,
        ],
      ),
    );
  }
}
