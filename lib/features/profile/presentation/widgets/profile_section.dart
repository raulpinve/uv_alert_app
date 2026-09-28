import 'package:flutter/material.dart';

/// Contenedor con fondo blanco translúcido y bordes redondeados
/// que agrupa varias [ProfileTile] (u otros widgets) en una sola tarjeta.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
