// lib/features/uv/presentation/widgets/recommendation_card.dart
import 'package:app/features/uv/data/uv.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:app/features/uv/presentation/widgets/info_card.dart';
import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
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
    final level = levelFor(uv);
    final color = uv < 0.5 ? const Color(0xFF5B6B8C) : level.color;
    return InfoCard(
      bg: bg,
      fg: fg,
      iconBg: color.withValues(alpha: 0.15),
      iconColor: color,
      icon: uv < 0.5 ? Icons.nights_stay_outlined : Icons.warning_amber_rounded,
      title: data.recommendation.name,
      body: data.recommendation.message,
    );
  }
}
