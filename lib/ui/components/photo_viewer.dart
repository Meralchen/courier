import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import 'glass.dart';

class PhotoViewerPage extends StatelessWidget {
  const PhotoViewerPage({
    super.key,
    required this.path,
    this.heroTag,
    this.caption,
  });

  final String path;
  final String? heroTag;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
      ),
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: image,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: GlassCircleButton(
              icon: Icons.close,
              color: Colors.white,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              child: Text(
                caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> openPhoto(
  BuildContext context, {
  required String path,
  String? heroTag,
  String? caption,
}) {
  if (path.isEmpty) return Future<void>.value();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: Motion.normal,
      reverseTransitionDuration: Motion.fast,
      pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) =>
          PhotoViewerPage(path: path, heroTag: heroTag, caption: caption),
      transitionsBuilder: (
        BuildContext _,
        Animation<double> animation,
        Animation<double> __,
        Widget child,
      ) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
