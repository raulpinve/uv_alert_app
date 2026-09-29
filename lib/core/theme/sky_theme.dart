import 'dart:math' as math;

import 'package:app/features/uv/data/uv.dart';
import 'package:flutter/material.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';

/// Degradado fijo de noche (el antiguo keyframe uv = 0).
const _nightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0B1B3A), Color(0xFF1B2F5E), Color(0xFF3A4A7A)],
  stops: [0.0, 0.55, 1.0],
);

/// 0 = pleno día, 1 = noche completa. Transiciona suave en el crepúsculo.
/// Si no le pasas sunrise/sunset, aproxima con 6:30 y 19:00 hora local.
double nightFactor({
  DateTime? sunrise,
  DateTime? sunset,
  DateTime? now,
  Duration twilight = const Duration(minutes: 30),
}) {
  final n = now ?? DateTime.now();
  final rise = sunrise?.toLocal() ?? DateTime(n.year, n.month, n.day, 6, 30);
  final set = sunset?.toLocal() ?? DateTime(n.year, n.month, n.day, 19, 0);

  double ramp(DateTime t, DateTime from, DateTime to) =>
      (t.difference(from).inSeconds / to.difference(from).inSeconds).clamp(
        0.0,
        1.0,
      );

  final dawn = 1 - ramp(n, rise.subtract(twilight), rise.add(twilight));
  final dusk = ramp(n, set.subtract(twilight), set.add(twilight));
  return math.max(dawn, dusk);
}

class SkyTheme {
  const SkyTheme._({
    required this.gradient,
    required this.fg,
    required this.cardColor,
    required this.night,
  });

  final LinearGradient gradient;
  final Color fg;
  final Color cardColor;
  final double night;

  bool get dark => night > 0.5;

  /// [uv] afecta el color de día; [night] (0..1) mezcla con el fondo nocturno.
  factory SkyTheme.from({required double uv, required double night}) {
    final gradient = LinearGradient.lerp(
      gradientForUv(uv),
      _nightGradient,
      night,
    )!;

    final fg = Color.lerp(const Color(0xFF1F2A37), Colors.white, night)!;
    final cardColor = Color.lerp(
      Colors.white.withValues(alpha: 0.72),
      Colors.white.withValues(alpha: 0.12),
      night,
    )!;

    return SkyTheme._(
      gradient: gradient,
      fg: fg,
      cardColor: cardColor,
      night: night,
    );
  }
}

extension UvDataSky on UvData {
  /// Factor de noche (0 = día, 1 = noche) según la hora de la ciudad.
  double get nightFactorForCity {
    final now = current.dateTime; // hora local de la ciudad

    DateTime? firstSun;
    DateTime? lastSun;
    final n = forecast.hours.length < forecast.uvClearSky.length
        ? forecast.hours.length
        : forecast.uvClearSky.length;

    for (var i = 0; i < n; i++) {
      final h = DateTime.tryParse(forecast.hours[i]);
      if (h == null) continue;
      final sameDay =
          h.year == now.year && h.month == now.month && h.day == now.day;
      if (!sameDay || forecast.uvClearSky[i] <= 0) continue;
      firstSun ??= h;
      lastSun = h;
    }

    // Sin datos del día completo: cae al respaldo 6:30 / 19:00
    // (pero respetando la hora de la ciudad).
    return nightFactor(
      now: now,
      sunrise: firstSun?.subtract(const Duration(minutes: 30)),
      sunset: lastSun?.add(const Duration(minutes: 30)),
    );
  }
}
