import 'dart:io' show Platform;

/// URL base del backend, ajustada automáticamente según la plataforma
/// donde corre la app (emulador Android, simulador iOS, dispositivo físico).
class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // El emulador de Android no ve "localhost" como tu PC, sino como
      // él mismo. 10.0.2.2 es la IP especial que sí apunta al host.
      return 'https://uv.gestorempresarial.cloud';
    }
    return 'https://uv.gestorempresarial.cloud'; // iOS simulator / desktop

    // Si pruebas en un dispositivo físico, reemplaza temporalmente por
    // la IP local de tu PC en la red, ej: 'http://192.168.1.15:3000'
  }
}
