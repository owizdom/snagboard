import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A ticket outline: ink border, 4 px corners, a half-circle notch at the top
/// and bottom of the perforation line, and a dashed line between them.
/// [stubWidth] is how far from the left edge the perforation sits.
class TicketShape extends StatelessWidget {
  const TicketShape({super.key, required this.child, this.stubWidth = 76});
  final Widget child;
  final double stubWidth;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TicketPainter(stubWidth), child: child);
}

class _TicketPainter extends CustomPainter {
  _TicketPainter(this.stubWidth);
  final double stubWidth;

  static const _notch = 8.0;
  static const _fill = Color(0xFFFBF9F3);

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Snag.radius)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(stubWidth, 0), radius: _notch))
      ..addOval(Rect.fromCircle(center: Offset(stubWidth, size.height), radius: _notch));
    final shape = Path.combine(PathOperation.difference, body, notches);
    canvas.drawPath(shape, Paint()..color = _fill);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Snag.outline
        ..color = Snag.ink,
    );
    final dash = Paint()
      ..strokeWidth = 1.5
      ..color = Snag.ink;
    for (var y = _notch + 6; y < size.height - _notch - 6; y += 9) {
      canvas.drawLine(Offset(stubWidth, y), Offset(stubWidth, y + 5), dash);
    }
  }

  @override
  bool shouldRepaint(_TicketPainter old) => old.stubWidth != stubWidth;
}
