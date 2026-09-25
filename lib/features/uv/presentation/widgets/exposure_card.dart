// lib/features/uv/presentation/widgets/exposure_card.dart
import 'package:app/features/uv/data/uv.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:app/features/uv/presentation/widgets/info_card.dart';
import 'package:flutter/material.dart';

class ExposureCard extends StatelessWidget {
  const ExposureCard({
    super.key,
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
    return InfoCard(
      bg: bg,
      fg: fg,
      iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.15),
      iconColor: const Color(0xFF2F6FDB),
      icon: Icons.wb_sunny_outlined,
      title: exposure.skinTypeName,
      body: exposure.message,
      trailing: Text(
        minutes == null ? '—' : '$minutes min',
        style: TextStyle(
          color: minutes == null
              ? fg.withValues(alpha: 0.6)
              : levelFor(uv).color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
