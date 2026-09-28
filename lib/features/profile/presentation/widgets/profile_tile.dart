import 'package:flutter/material.dart';

/// Fila estilo "ajustes": icono/avatar a la izquierda, título + valor
/// en el centro y chevron a la derecha. Usada dentro de [ProfileSection].
class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String value;
  final VoidCallback onTap;

  static const _ink = Color(0xFF1F2A37);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _ink.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
