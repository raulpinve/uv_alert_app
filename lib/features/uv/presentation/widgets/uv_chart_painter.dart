// lib/features/uv/presentation/widgets/uv_chart_painter.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

class UvChartPainter extends CustomPainter {
  UvChartPainter({
    required this.values,
    required this.currentHour,
    required this.lineColor,
    required this.baseColor,
  });

  final List<double> values;
  final int currentHour;
  final Color lineColor, baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxY = math.max(11.0, values.reduce(math.max));
    final n = values.length;

    Offset pt(int i) => Offset(
      i / (n - 1) * size.width,
      size.height - (values[i] / maxY) * (size.height - 8) - 2,
    );

    // Línea base
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      Paint()
        ..color = baseColor
        ..strokeWidth = 1,
    );

    // Curva suavizada
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < n; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    // Punto de la hora actual
    final h = currentHour.clamp(0, n - 1);
    canvas.drawCircle(pt(h), 5, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(UvChartPainter o) =>
      o.values != values || o.currentHour != currentHour;
}
