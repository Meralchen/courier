import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/avatar.dart';
import '../components/pressable.dart';

/// The iOS story strip above the chat list: each poster's avatar sits in a
/// sweeping gradient ring while any of their stories is unviewed, and in a flat
/// grey ring once everything has been seen.
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key, required this.stories, required this.onOpen});

  final List<StoryCircle> stories;
  final ValueChanged<StoryCircle> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
        itemCount: stories.length,
        itemBuilder: (BuildContext context, int index) {
          final StoryCircle story = stories[index];
          return Pressable(
            onTap: () => onOpen(story),
            scale: 0.93,
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StoryRing(
                    unread: story.unread,
                    accent: colors.accent,
                    idle: colors.separator,
                    child: Avatar(
                      title: story.title,
                      seed: story.chatId,
                      size: 58,
                      photoFileId: story.photoFileId,
                      photoPath: story.photoPath,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      story.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One avatar in its ring. Public so a test can assert the unread state without
/// reading pixels.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.child,
    required this.accent,
    required this.idle,
    this.unread = false,
  });

  final Widget child;
  final Color accent;
  final Color idle;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: unread ? 'Unviewed story' : 'Viewed story',
      child: SizedBox(
        width: 66,
        height: 66,
        child: CustomPaint(
          painter: _RingPainter(unread: unread, accent: accent, idle: idle),
          child: Padding(
            padding: const EdgeInsets.all(3.2),
            child: ClipOval(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.unread,
    required this.accent,
    required this.idle,
  });

  final bool unread;
  final Color accent;
  final Color idle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Offset center = size.center(Offset.zero);
    final double stroke = 2.6;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (unread) {
      // The iOS ring: blue into violet into pink and back to blue, starting at
      // twelve o'clock instead of three.
      paint.shader = SweepGradient(
        colors: <Color>[
          accent,
          const Color(0xFF6C5CE7),
          const Color(0xFFFF375F),
          accent,
        ],
        stops: const <double>[0, 0.42, 0.74, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Offset.zero & size);
    } else {
      paint.color = idle;
    }
    canvas.drawCircle(center, size.shortestSide / 2 - stroke / 2, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.unread != unread ||
      oldDelegate.accent != accent ||
      oldDelegate.idle != idle;
}
