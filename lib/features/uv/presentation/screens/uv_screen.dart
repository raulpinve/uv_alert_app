import 'dart:io';
import 'dart:async';

import 'package:app/core/network/api_exception.dart';
import 'package:app/features/auth/data/auth_service.dart';
import 'package:app/features/uv/presentation/widgets/cloud_reduction_chip.dart';
import 'package:app/features/profile/presentation/screens/profile_screen.dart';
import 'package:app/features/uv/data/uv.dart';
import 'package:app/features/uv/data/uv_service.dart';
import 'package:app/features/uv/presentation/widgets/exposure_card.dart';
import 'package:app/features/uv/presentation/widgets/forecast_section.dart';
import 'package:app/features/uv/presentation/widgets/recommendation_card.dart';
import 'package:app/features/uv/presentation/widgets/uv_header.dart';
import 'package:app/features/uv/presentation/widgets/uv_level_chip.dart';
import 'package:app/features/uv/presentation/widgets/uv_ring.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/sky_theme.dart';
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
  bool _accountMissing = false;
  double _night = nightFactor();

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
      setState(() {
        _data = res.data;
        _accountMissing = false;
        _night = res.data?.nightFactorForCity ?? nightFactor();
      });
    } on ApiException catch (e) {
      if (e.isNotFound) {
        // Error no transitorio: la cuenta o el dispositivo ya no existen
        // en el backend. Reintentar la misma consulta nunca va a
        // funcionar — hace falta volver a sincronizar desde cero, lo
        // cual solo pasa vía logout/login (AuthGate).
        if (!mounted) return;
        setState(() {
          _error = _mensajeAmigable(e);
          _data = null;
          _accountMissing = true;
        });
      } else {
        // Otro ApiException (401, 500, etc.): tratado como transitorio,
        // se mantienen los datos previos si existían.
        if (!mounted) return;
        setState(() {
          _error = _mensajeAmigable(e);
          _accountMissing = false;
        });
      }
    } catch (e) {
      // Error transitorio (red, timeout, 5xx): se mantienen los datos
      // previos si existían, solo se avisa.
      if (!mounted) return;
      setState(() {
        _error = _mensajeAmigable(e);
        _accountMissing = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensajeAmigable(Object e) {
    if (e is ApiException) {
      return e.displayMessage;
    }
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
    final sky = SkyTheme.from(uv: uv, night: _night);
    final fg = sky.fg;
    final cardColor = sky.cardColor;
    final dark = sky.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: sky.gradient),
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
                              onPressed: _accountMissing
                                  ? () => AuthService().signOut()
                                  : _load,
                              child: Text(
                                _accountMissing
                                    ? 'Cerrar sesión'
                                    : 'Reintentar',
                              ),
                            ),
                          ],
                        ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (_error != null) ...[
                        _StaleDataBanner(
                          message: _error!,
                          fg: fg,
                          bg: cardColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      UvHeader(
                        data: data,
                        fg: fg,
                        dark: dark,
                        onProfile: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(sky: sky),
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
                      const SizedBox(height: 8),
                      Center(
                        child: CloudReductionChip(
                          uv: uv,
                          uvClearSky: data.current.uvClearSky,
                          fg: fg,
                          dark: dark,
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

/// Aviso discreto mostrado cuando el refresh falló pero seguimos
/// mostrando datos previos (error transitorio: red, timeout, 5xx).
class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner({
    required this.message,
    required this.fg,
    required this.bg,
  });

  final String message;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: fg.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
