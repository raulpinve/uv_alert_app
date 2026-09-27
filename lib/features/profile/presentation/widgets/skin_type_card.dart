// lib/features/profile/presentation/widgets/skin_type_card.dart
import 'package:app/features/profile/data/skin_type.dart';
import 'package:flutter/material.dart';

/// Tarjeta seleccionable con el círculo de color, nombre y descripción
/// de un [SkinType], usada en la grilla del selector.
class SkinTypeCard extends StatelessWidget {
  const SkinTypeCard({
    super.key,
    required this.type,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final SkinType type;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  static const _ink = Color(0xFF1F2A37);

  @override
  Widget build(BuildContext context) {
    final checkColor = type.color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.92 : 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: type.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: selected ? Icon(Icons.check, color: checkColor) : null,
            ),
            const SizedBox(height: 10),
            Text(
              type.name,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.description,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
