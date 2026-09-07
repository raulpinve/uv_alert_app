import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Maneja permisos, obtención del token FCM y visualización de
/// notificaciones locales. FCM no muestra automáticamente una
/// notificación cuando la app está en primer plano (foreground) en
/// Android, por eso usamos flutter_local_notifications para eso.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'uv_alerts',
    'Alertas de UV',
    description: 'Notificaciones sobre cambios en el índice UV',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Llamar una sola vez, idealmente en main() antes de runApp().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Pide permiso de notificaciones (obligatorio en iOS y en
    // Android 13+; en versiones anteriores de Android no hace nada).
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Mensajes recibidos mientras la app está abierta.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // El usuario tocó la notificación y la app se abrió desde
    // background (no estaba terminada).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notificación abierta desde background: ${message.data}');
      // Aquí podrías navegar a una pantalla específica si lo necesitas.
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Token FCM actual del dispositivo. Puede ser null en simuladores
  /// de iOS o si el servicio de Google Play no está disponible.
  Future<String?> getToken() => _messaging.getToken();

  /// Firebase puede renovar el token en cualquier momento (no solo al
  /// instalar la app) — hay que escuchar esto y re-registrar el
  /// dispositivo en el backend cuando ocurra.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

/// Handler para mensajes recibidos con la app en background o
/// terminada. DEBE ser una función de nivel superior (top-level, fuera
/// de cualquier clase) y se registra en main() antes de runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensaje recibido en background: ${message.messageId}');
  // Nota: aquí NO se puede actualizar UI directamente. Si necesitas
  // hacer algo (como guardar datos), hazlo con almacenamiento local.
}
