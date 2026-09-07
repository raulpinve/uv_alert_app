import 'dart:convert';

import 'package:app/config/api_config.dart';
import 'package:http/http.dart' as http;

class DeviceService {
  DeviceService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<void> registrarDispositivo({
    required String fcmToken,
    required double latitud,
    required double longitud,
  }) async {
    final uri = Uri.parse('$baseUrl/dispositivos');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fcm_token': fcmToken,
        'latitud': latitud,
        'longitud': longitud,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al registrar el dispositivo (status ${response.statusCode})',
      );
    }
  }
}
