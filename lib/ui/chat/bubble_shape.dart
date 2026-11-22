import 'package:material_ui/material_ui.dart';

BorderRadius bubbleRadius({
  required bool outgoing,
  required bool isFirst,
  required bool isLast,
}) {
  const Radius round = Radius.circular(18);
  const Radius tight = Radius.circular(7);
  if (outgoing) {
    return BorderRadius.only(
      topLeft: round,
      topRight: isFirst ? round : tight,
      bottomLeft: round,
      bottomRight: isLast ? tight : round,
    );
  }
  return BorderRadius.only(
    topLeft: isFirst ? round : tight,
    topRight: round,
    bottomLeft: isLast ? tight : round,
    bottomRight: round,
  );
}

class BubbleTail extends StatelessWidget {
  const BubbleTail({
    super.key,
    required this.color,
    required this.outgoing,
  });

  final Color color;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(9, 11),
      painter: _TailPainter(color: color, outgoing: outgoing),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.color, required this.outgoing});

  final Color color;
  final bool outgoing;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (outgoing) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.7, 0, size.width, size.height);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.75, 0, size.height * 0.55);
    } else {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.3, 0, 0, size.height);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.75, size.width, size.height * 0.55);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.outgoing != outgoing;
}
