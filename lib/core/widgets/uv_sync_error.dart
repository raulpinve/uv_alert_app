import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:flutter/material.dart';

/// Estado de error mostrado cuando falla la sincronización de usuario
/// (POST /auth/sync) al iniciar sesión.
///
/// Usa el mismo fondo "sin datos" que ya define UvScreen implícitamente
/// (gradientForUv(0), el degradado nocturno) con texto blanco, para no
/// introducir un lenguaje visual distinto al resto de la app.
class UvSyncError extends StatelessWidget {
  const UvSyncError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final cardColor = Colors.white.withValues(alpha: 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(gradient: gradientForUv(0)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 28,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No pudimos sincronizar tu cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisa tu conexión e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onRetry,
                      child: const Text('Reintentar'),
                    ),
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
