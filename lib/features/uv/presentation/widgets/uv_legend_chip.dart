// lib/features/uv/presentation/widgets/uv_legend_chip.dart
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:flutter/material.dart';

class UvLegendChip extends StatelessWidget {
  const UvLegendChip({super.key, required this.level, required this.dark});

  final UvLevel level;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.85 : 0.7),
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
