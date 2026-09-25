// lib/features/uv/presentation/screens/uv_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:app/features/profile/presentation/screens/profile_screen.dart';
import 'package:app/features/uv/data/uv.dart';
import 'package:app/features/uv/data/uv_service.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:app/features/uv/presentation/widgets/exposure_card.dart';
import 'package:app/features/uv/presentation/widgets/forecast_section.dart';
import 'package:app/features/uv/presentation/widgets/recommendation_card.dart';
import 'package:app/features/uv/presentation/widgets/uv_header.dart';
import 'package:app/features/uv/presentation/widgets/uv_level_chip.dart';
import 'package:app/features/uv/presentation/widgets/uv_ring.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      setState(() => _error = _mensajeAmigable(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensajeAmigable(Object e) {
    if (e is SocketException) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión.';
    }
    if (e is http.ClientException) {
      return 'No se pudo conectar con el servidor. Intenta de nuevo.';
    }
    if (e is TimeoutException) {
      return 'La conexión tardó demasiado. Intenta de nuevo.';
    }
    // Mensajes que tú mismo lanzaste con Exception('texto') en UvService
    if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final uv = data?.current.uv ?? 0;
    final dark = uv < 1; // fondo nocturno → texto claro
    final fg = dark ? Colors.white : const Color(0xFF1F2A37);
    final cardColor = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);

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
                      UvHeader(
                        data: data,
                        fg: fg,
                        dark: dark,
                        onProfile: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                          if (changed == true) {
                            _load(); // recalcula los minutos de exposición
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      UvRing(uv: uv, fg: fg, dark: dark),
                      const SizedBox(height: 16),
                      UvLevelChip(uv: uv, dark: dark),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'cielo despejado: ${data.current.uvClearSky.toStringAsFixed(1)} uv',
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      RecommendationCard(
                        data: data,
                        uv: uv,
                        fg: fg,
                        bg: cardColor,
                      ),
                      if (data.exposure != null) ...[
                        const SizedBox(height: 12),
                        ExposureCard(data: data, uv: uv, fg: fg, bg: cardColor),
                      ],
                      const SizedBox(height: 24),
                      ForecastSection(
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
