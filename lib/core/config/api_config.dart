import 'dart:io' show Platform;

/// URL base del backend, ajustada automáticamente según la plataforma
/// donde corre la app (emulador Android, simulador iOS, dispositivo físico).
class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Emulador Android: 10.0.2.2 apunta al localhost de tu PC.
      return 'http://10.0.2.2:3000';

      // Producción:
      // return 'https://uv.gestorempresarial.cloud';

      // Dispositivo Android físico:
      // return 'http://192.168.10.14:3000';
    }

    // iOS Simulator / Desktop:
    // return 'http://localhost:3000';

    // Producción:
    // return 'https://uv.gestorempresarial.cloud';

    return 'http://localhost:3000';
  }
}
