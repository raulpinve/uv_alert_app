// lib/features/uv/presentation/widgets/uv_level_chip.dart
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:flutter/material.dart';

class UvLevelChip extends StatelessWidget {
  const UvLevelChip({super.key, required this.uv, required this.dark});

  final double uv;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final level = levelFor(uv);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: dark ? 0.85 : 0.75),
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
