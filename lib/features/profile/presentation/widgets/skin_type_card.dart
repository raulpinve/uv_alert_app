import 'package:app/features/profile/data/models/skin_type.dart';
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
  static const _accent = Color(0xFF2F6FDB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        scale: selected ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.95 : 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                  ),
                  if (selected)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                type.name,
                style: TextStyle(
                  color: selected ? _accent : _ink,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 32, // reserva espacio fijo para 2 líneas
                child: Text(
                  type.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
