import 'dart:async';

import 'package:app/models/uv.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/device_service.dart';
import 'package:app/services/location_service.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/uv_service.dart';
import 'package:flutter/material.dart';

/// Pantalla principal que muestra el Índice UV actual y las próximas
/// horas del día, usando datos reales del endpoint /uv.
class UvIndexScreen extends StatefulWidget {
  const UvIndexScreen({super.key});

  @override
  State<UvIndexScreen> createState() => _UvIndexScreenState();
}

class _UvIndexScreenState extends State<UvIndexScreen> {
  final _service = UvService();
  final _deviceService = DeviceService();
  final _locationService = LocationService();
  late Future<UvResponse> _future;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  void initState() {
    super.initState();
    _future = _initialize();

    // Si Firebase renueva el token FCM mientras la app está abierta,
    // re-registramos el dispositivo con el nuevo token.
    _tokenRefreshSub = NotificationService.instance.onTokenRefresh.listen(
      _handleTokenRefresh,
    );
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final position = await _locationService.getCurrentPosition();
      await _deviceService.registrarDispositivo(
        fcmToken: newToken,
        latitud: position.latitude,
        longitud: position.longitude,
      );
    } catch (e) {
      debugPrint('Error al re-registrar dispositivo tras refresh de token: $e');
    }
  }

  /// 1. Obtiene el token FCM real del dispositivo.
  /// 2. Obtiene la ubicación actual.
  /// 3. Registra el dispositivo en el backend (fcm_token + ubicación).
  /// 4. Recién entonces carga los datos de UV, usando el mismo token.
  Future<UvResponse> _initialize() async {
    final token = await NotificationService.instance.getToken();
    if (token == null) {
      throw Exception('No se pudo obtener el token de notificaciones.');
    }

    final position = await _locationService.getCurrentPosition();

    await _deviceService.registrarDispositivo(
      fcmToken: token,
      latitud: position.latitude,
      longitud: position.longitude,
    );

    return _service.fetchUv(fcmToken: token);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _initialize();
    });
    await _future;
  }

  /// Mapea el valor UV a un color, siguiendo la escala estándar de la OMS.
  static Color colorForUv(double uv) {
    if (uv <= 2) return const Color(0xFF4CAF50); // Bajo - verde
    if (uv <= 5) return const Color(0xFFFFC107); // Moderado - amarillo
    if (uv <= 7) return const Color(0xFFFF9800); // Alto - naranja
    if (uv <= 10) return const Color(0xFFF4511E); // Muy alto - rojo
    return const Color(0xFF9C27B0); // Extremo - morado
  }

  static String labelForUv(double uv) {
    if (uv <= 2) return 'Bajo';
    if (uv <= 5) return 'Moderado';
    if (uv <= 7) return 'Alto';
    if (uv <= 10) return 'Muy alto';
    return 'Extremo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: FutureBuilder<UvResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!.data;

            return RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildHeroCard(data),
                    const SizedBox(height: 20),
                    _buildStatsRow(data),
                    const SizedBox(height: 20),
                    _buildHourlySection(data),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Home', style: TextStyle(color: Colors.grey, fontSize: 14)),
        Row(
          children: [
            _circleIconButton(
              icon: Icons.logout,
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Confirmación simple antes de cerrar sesión.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await AuthService().signOut();
      // No hace falta navegar manualmente: el AuthGate reacciona solo
      // al cambio de authStateChanges y muestra LoginScreen.
    }
  }

  Widget _buildHeroCard(UvData data) {
    final uvColor = colorForUv(data.actual.uv);
    final hora = data.actual.hora;
    final isDay = hora.hour >= 6 && hora.hour < 18;

    // Colores de fondo según el momento del día.
    final backgroundColors = isDay
        ? [
            const Color(0xFF039BE5),
            const Color(0xFF4FC3F7),
            const Color(0xFF8FD8F8),
          ] // cielo azul con profundidad
        : [const Color(0xFF0D1333), const Color(0xFF1B2249)]; // noche

    final primaryTextColor = isDay ? Colors.grey.shade800 : Colors.white;
    final secondaryTextColor = isDay
        ? Colors.white.withOpacity(0.9)
        : Colors.grey.shade400;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundColors,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Nubes sutiles de fondo, solo de día.
            if (isDay) ..._buildClouds(),
            // Estrellas sutiles de fondo, solo de noche.
            if (!isDay) ..._buildStars(),

            // Círculo: sol (coloreado por UV) de día, luna de noche.
            Positioned(
              right: -60,
              top: -20,
              child: isDay
                  ? Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            uvColor.withOpacity(0.95),
                            uvColor.withOpacity(0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: uvColor.withOpacity(0.35),
                            blurRadius: 50,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    )
                  : _buildMoon(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _saludo(hora.hour),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_weekday(hora.weekday)}, ${hora.day} ${_month(hora.month)}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actualizado a las ${_formatHour(hora)}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        data.ciudad,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.actual.uv.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          height: 1,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Índice UV · ${labelForUv(data.actual.uv)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      _buildClearSkyNote(data, isDay),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Círculo de luna: gris claro con "cráteres" sutiles y un leve resplandor.
  Widget _buildMoon() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade500.withOpacity(0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(left: 40, top: 50, child: _crater(18)),
          Positioned(left: 90, top: 30, child: _crater(12)),
          Positioned(left: 100, top: 90, child: _crater(22)),
        ],
      ),
    );
  }

  Widget _crater(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade600.withOpacity(0.3),
      ),
    );
  }

  /// Nubes blancas semi-transparentes, solo visibles de día, para dar
  /// textura al cielo. Posicionadas en la parte baja/lateral de la
  /// tarjeta para no tapar el texto (saludo, fecha, número de UV).
  List<Widget> _buildClouds() {
    return [
      Positioned(
        left: -20,
        bottom: 70,
        child: _cloud(width: 65, height: 20, opacity: 0.28),
      ),
      Positioned(
        right: 20,
        bottom: 100,
        child: _cloud(width: 50, height: 16, opacity: 0.22),
      ),
      Positioned(
        left: 30,
        bottom: 20,
        child: _cloud(width: 55, height: 18, opacity: 0.25),
      ),
    ];
  }

  Widget _cloud({
    required double width,
    required double height,
    required double opacity,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }

  /// Puntitos blancos aleatorios (pero fijos) simulando estrellas.
  List<Widget> _buildStars() {
    const positions = [
      Offset(20, 20),
      Offset(60, 45),
      Offset(100, 15),
      Offset(140, 60),
      Offset(30, 90),
      Offset(180, 30),
      Offset(200, 80),
      Offset(10, 130),
    ];

    return positions
        .map(
          (p) => Positioned(
            left: p.dx,
            top: p.dy,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        )
        .toList();
  }

  /// Nota aclaratoria: el UV actual puede estar reducido por nubosidad.
  /// Si se despeja el cielo, el UV real subiría hasta uv_clear_sky.
  Widget _buildClearSkyNote(UvData data, bool isDay) {
    final real = data.actual.uv;
    final clearSky = data.actual.uvClearSky;
    final diff = clearSky - real;

    // Si la diferencia es mínima (< 0.5), el cielo ya está despejado
    // y no tiene sentido mostrar la aclaración.
    if (diff < 0.5) return const SizedBox.shrink();

    final bgColor = isDay
        ? Colors.white.withOpacity(0.6)
        : Colors.white.withOpacity(0.12);
    final textColor = isDay ? Colors.grey.shade600 : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Este es el UV actual (parcialmente nublado). '
                'Con cielo despejado sería ${clearSky.toStringAsFixed(1)} '
                '(${labelForUv(clearSky)}).',
                style: TextStyle(fontSize: 11, color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(UvData data) {
    // % de nubosidad estimado: qué tanto el UV real está por debajo
    // del UV de cielo despejado (uv_clear_sky) en este momento.
    final clearSky = data.actual.uvClearSky;
    final real = data.actual.uv;
    final reduccion = clearSky > 0
        ? (((clearSky - real) / clearSky) * 100).clamp(0, 100)
        : 0.0;

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.wb_sunny_outlined,
              label: 'Nivel UV',
              value: labelForUv(data.actual.uv),
            ),
            _StatItem(
              icon: Icons.wb_cloudy_outlined,
              label: 'Cielo despejado',
              value: clearSky.toStringAsFixed(1),
            ),
            _StatItem(
              icon: Icons.cloud_outlined,
              label: 'Reducción nubes',
              value: '${reduccion.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }

  // --- Próximas horas del día (a partir de la hora actual) ---
  Widget _buildHourlySection(UvData data) {
    final ahora = data.actual.hora;
    // Solo horas futuras con UV real (> 0): una vez que el sol se pone,
    // no tiene sentido seguir listando horas con UV en cero.
    final proximas = data.proyeccion.points
        .where((p) => p.hora.isAfter(ahora) && p.uv > 0.05)
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximas horas',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (proximas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No hay más horas con datos para hoy.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ...proximas.map((p) => _HourTile(point: p)),
        ],
      ),
    );
  }

  String _saludo(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatHour(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min $ampm';
  }

  String _weekday(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  String _month(int month) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.point});

  final UvHourPoint point;

  @override
  Widget build(BuildContext context) {
    final uvColor = _UvIndexScreenState.colorForUv(point.uv);
    final h = point.hora.hour % 12 == 0 ? 12 : point.hora.hour % 12;
    final ampm = point.hora.hour < 12 ? 'AM' : 'PM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: uvColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny, color: uvColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            point.uv.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$h:00 $ampm',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Uso: UvIndexScreen(fcmToken: 'fcm-token-prueba-123457')
// No olvides agregar http: ^1.2.0 en pubspec.yaml
// --------------------------------------------------------------------------
