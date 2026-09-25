// lib/screens/uv_screen.dart
import 'dart:math' as math;

import 'package:app/models/uv.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/services/uv_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

// ───────────────────────────── Pantalla ─────────────────────────────

class UvScreen extends StatefulWidget {
  const UvScreen({super.key});

  @override
  State<UvScreen> createState() => _UvScreenState();
}

class _UvScreenState extends State<UvScreen> {
  final _service = UvService();
  UvData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    debugPrint('[${DateTime.now()}] UvScreen pidiendo fetch de UV');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        throw Exception('No se pudo obtener el token de notificaciones.');
      }

      final res = await _service.fetchUv(fcmToken: fcmToken);
      if (!mounted) return;
      setState(() => _data = res.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final uv = data?.current.uv ?? 0;
    final dark = uv < 1; // fondo nocturno → texto claro
    final fg = dark ? Colors.white : const Color(0xFF1F2A37);
    final cardColor = dark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.72);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: gradientForUv(uv)),
        child: SafeArea(
          child: data == null
              ? Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error ?? 'Sin datos',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: fg),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _Header(
                        data: data,
                        fg: fg,
                        dark: dark,
                        onRefresh: _load,
                        onProfile: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                          if (changed == true)
                            _load(); // recalcula los minutos de exposición
                        },
                      ),
                      const SizedBox(height: 20),
                      _UvRing(uv: uv, fg: fg, dark: dark),
                      const SizedBox(height: 16),
                      _LevelChip(uv: uv, dark: dark),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'cielo despejado: ${data.current.uvClearSky.toStringAsFixed(1)} uv',
                          style: TextStyle(
                            color: fg.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _RecommendationCard(
                        data: data,
                        uv: uv,
                        fg: fg,
                        bg: cardColor,
                      ),
                      if (data.exposure != null) ...[
                        const SizedBox(height: 12),
                        _ExposureCard(
                          data: data,
                          uv: uv,
                          fg: fg,
                          bg: cardColor,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _ForecastSection(
                        data: data,
                        fg: fg,
                        bg: cardColor,
                        dark: dark,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Header ─────────────────────────────

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

class _Header extends StatelessWidget {
  const _Header({
    required this.data,
    required this.fg,
    required this.onRefresh,
    required this.dark,
    required this.onProfile,
  });

  final UvData data;
  final Color fg;
  final VoidCallback onRefresh;
  final bool dark;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final t = data.current.dateTime;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final fecha =
        '${_dias[t.weekday - 1]} ${t.day} de ${_meses[t.month - 1]} · $hh:$mm';
    final box = Colors.white.withOpacity(dark ? 0.15 : 0.55);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: box,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.location_on_outlined, color: fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.city,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                fecha,
                style: TextStyle(color: fg.withOpacity(0.8), fontSize: 13),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onRefresh,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: box, shape: BoxShape.circle),
            child: Icon(Icons.refresh, color: fg, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onProfile,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: box, shape: BoxShape.circle),
            child: Icon(Icons.person_outline, color: fg, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Anillo UV ───────────────────────────

class _UvRing extends StatelessWidget {
  const _UvRing({required this.uv, required this.fg, required this.dark});

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
              rayColor: fg.withOpacity(0.5),
              fill: Colors.white.withOpacity(dark ? 0.08 : 0.3),
              track: Colors.white.withOpacity(dark ? 0.15 : 0.35),
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
                    style: TextStyle(color: fg.withOpacity(0.85)),
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

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.uv, required this.dark});

  final double uv;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final level = levelFor(uv);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(dark ? 0.85 : 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          uv < 0.5 ? 'sin uv' : level.label,
          style: TextStyle(
            color: uv < 0.5 ? const Color(0xFF1B2F5E) : level.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Tarjetas ─────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.bg,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.fg,
    this.trailing,
  });

  final Color bg, iconBg, iconColor, fg;
  final IconData icon;
  final String title, body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: fg.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.data,
    required this.uv,
    required this.fg,
    required this.bg,
  });

  final UvData data;
  final double uv;
  final Color fg, bg;

  @override
  Widget build(BuildContext context) {
    final level = levelFor(uv);
    final color = uv < 0.5 ? const Color(0xFF5B6B8C) : level.color;
    return _InfoCard(
      bg: bg,
      fg: fg,
      iconBg: color.withOpacity(0.15),
      iconColor: color,
      icon: uv < 0.5 ? Icons.nights_stay_outlined : Icons.warning_amber_rounded,
      title: data.recommendation.name,
      body: data.recommendation.message,
    );
  }
}

class _ExposureCard extends StatelessWidget {
  const _ExposureCard({
    required this.data,
    required this.uv,
    required this.fg,
    required this.bg,
  });

  final UvData data;
  final double uv;
  final Color fg, bg;

  @override
  Widget build(BuildContext context) {
    final exposure = data.exposure;
    if (exposure == null) return const SizedBox.shrink();

    final minutes = exposure.minutes;
    return _InfoCard(
      bg: bg,
      fg: fg,
      iconBg: const Color(0xFF3B82F6).withOpacity(0.15),
      iconColor: const Color(0xFF2F6FDB),
      icon: Icons.wb_sunny_outlined,
      title: exposure.skinTypeName,
      body: exposure.message,
      trailing: Text(
        minutes == null ? '—' : '$minutes min',
        style: TextStyle(
          color: minutes == null ? fg.withOpacity(0.6) : levelFor(uv).color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ─────────────────────────── Pronóstico ───────────────────────────

class _ForecastSection extends StatelessWidget {
  const _ForecastSection({
    required this.data,
    required this.fg,
    required this.bg,
    required this.dark,
  });

  final UvData data;
  final Color fg, bg;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final values = data.forecast.uv;
    var peak = 0.0;
    var peakHour = 0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > peak) {
        peak = values[i];
        peakHour = i;
      }
    }
    final currentHour = data.current.dateTime.hour;
    final peakLevel = levelFor(peak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pronóstico de hoy',
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(dark ? 0.85 : 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'pico ${peak.toStringAsFixed(1)} · ${peakHour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  color: peak < 0.5 ? const Color(0xFF1B2F5E) : peakLevel.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ChartPainter(
                    values: values,
                    currentHour: currentHour,
                    lineColor: dark ? Colors.white : const Color(0xFFA92B2B),
                    baseColor: fg.withOpacity(0.15),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['00', '06', '12', '18', '23']
                    .map(
                      (e) => Text(
                        e,
                        style: TextStyle(
                          color: fg.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UvLevel.values
              .map((l) => _LegendChip(level: l, dark: dark))
              .toList(),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.level, required this.dark});

  final UvLevel level;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(dark ? 0.85 : 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              color: level.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
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
  bool shouldRepaint(_ChartPainter o) =>
      o.values != values || o.currentHour != currentHour;
}
