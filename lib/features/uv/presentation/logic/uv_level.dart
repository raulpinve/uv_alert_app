// lib/features/uv/presentation/logic/uv_level.dart
import 'package:flutter/material.dart';

// ───────────────────────── Niveles y colores ─────────────────────────

enum UvLevel { bajo, moderado, alto, muyAlto, extremo }

UvLevel levelFor(double uv) {
  if (uv < 3) return UvLevel.bajo;
  if (uv < 6) return UvLevel.moderado;
  if (uv < 8) return UvLevel.alto;
  if (uv < 11) return UvLevel.muyAlto;
  return UvLevel.extremo;
}

extension UvLevelX on UvLevel {
  String get label => switch (this) {
    UvLevel.bajo => 'bajo',
    UvLevel.moderado => 'moderado',
    UvLevel.alto => 'alto',
    UvLevel.muyAlto => 'muy alto',
    UvLevel.extremo => 'extremo',
  };

  Color get color => switch (this) {
    UvLevel.bajo => const Color(0xFF3E8E41),
    UvLevel.moderado => const Color(0xFFB8860B),
    UvLevel.alto => const Color(0xFFE0621F),
    UvLevel.muyAlto => const Color(0xFFA92B2B),
    UvLevel.extremo => const Color(0xFF7B3FA0),
  };
}

/// Keyframes del degradado: [uv, arriba, medio, abajo]
class _Keyframe {
  const _Keyframe(this.uv, this.top, this.mid, this.bottom);
  final double uv;
  final Color top, mid, bottom;
}

const _keyframes = <_Keyframe>[
  // Noche / sin UV
  _Keyframe(0, Color(0xFF0B1B3A), Color(0xFF1B2F5E), Color(0xFF3A4A7A)),
  // Bajo: cielo azul
  _Keyframe(2, Color(0xFF5AA9E6), Color(0xFF9CCBEF), Color(0xFFD6ECF7)),
  // Moderado: amarillo
  _Keyframe(5, Color(0xFF6BB5EA), Color(0xFFF3E7A8), Color(0xFFF7CF74)),
  // Alto: naranja suave
  _Keyframe(7, Color(0xFF66B3EA), Color(0xFFEFDCA0), Color(0xFFF5A65B)),
  // Muy alto (como tu captura)
  _Keyframe(10, Color(0xFF5DB4EC), Color(0xFFF6E6B4), Color(0xFFF29A55)),
  // Extremo
  _Keyframe(12, Color(0xFF8A6FD1), Color(0xFFE9A0C0), Color(0xFFE8604C)),
];

LinearGradient gradientForUv(double uv) {
  final v = uv.clamp(0.0, 12.0);
  var a = _keyframes.first;
  var b = _keyframes.last;
  for (var i = 0; i < _keyframes.length - 1; i++) {
    if (v >= _keyframes[i].uv && v <= _keyframes[i + 1].uv) {
      a = _keyframes[i];
      b = _keyframes[i + 1];
      break;
    }
  }
  final t = b.uv == a.uv ? 0.0 : (v - a.uv) / (b.uv - a.uv);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.lerp(a.top, b.top, t)!,
      Color.lerp(a.mid, b.mid, t)!,
      Color.lerp(a.bottom, b.bottom, t)!,
    ],
    stops: const [0.0, 0.55, 1.0],
  );
}
