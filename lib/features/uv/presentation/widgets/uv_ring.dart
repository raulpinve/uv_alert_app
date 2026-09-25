// lib/features/uv/presentation/widgets/uv_ring.dart
import 'dart:math' as math;

import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:flutter/material.dart';

class UvRing extends StatelessWidget {
  const UvRing({
    super.key,
    required this.uv,
    required this.fg,
    required this.dark,
  });

  final double uv;
  final Color fg;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final level = levelFor(uv);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: uv),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox(
          width: 250,
          height: 250,
          child: CustomPaint(
            painter: _RingPainter(
              progress: (value / 11).clamp(0.0, 1.0),
              color: dark ? Colors.white70 : level.color,
              rayColor: fg.withValues(alpha: 0.5),
              fill: Colors.white.withValues(alpha: dark ? 0.08 : 0.3),
              track: Colors.white.withValues(alpha: dark ? 0.15 : 0.35),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    uv.toStringAsFixed(1),
                    style: TextStyle(
                      color: fg,
                      fontSize: 58,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'índice UV',
                    style: TextStyle(color: fg.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.rayColor,
    required this.fill,
    required this.track,
  });

  final double progress;
  final Color color, rayColor, fill, track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 34;
    const stroke = 12.0;

    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Rayos de sol
    final ray = Paint()
      ..color = rayColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 12; k++) {
      if (k == 0 || k == 6) continue; // sin rayos arriba/abajo
      final a = -math.pi / 2 + k * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r + 22),
        c + Offset(math.cos(a), math.sin(a)) * (r + 34),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color;
}
