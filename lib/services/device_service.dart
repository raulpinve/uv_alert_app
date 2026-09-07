import 'dart:convert';

import 'package:app/config/api_config.dart';
import 'package:app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'fcm_token': fcmToken,
        'latitud': latitud,
        'longitud': longitud,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al registrar el dispositivo '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> desregistrarDispositivo() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final fcmToken = await NotificationService.instance.getToken();

    if (fcmToken == null) {
      return;
    }

    final idToken = await user.getIdToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/dispositivos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al desregistrar dispositivo '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
  }
}
