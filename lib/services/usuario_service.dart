import 'package:app/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UsuarioService {
  UsuarioService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  /// Registra al usuario en el backend (si no existe) usando su token de
  /// Firebase. Debe llamarse antes de registrar el dispositivo, ya que
  /// `dispositivos` depende de que el usuario exista en la tabla `usuarios`.
  Future<void> registrarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al registrar el usuario '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
  }
}
