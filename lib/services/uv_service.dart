import 'dart:convert';

import 'package:app/config/api_config.dart';
import 'package:app/models/uv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

class UvService {
  UvService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<UvResponse> fetchUv({required String fcmToken}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final idToken = await user.getIdToken();

    final uri = Uri.parse('$baseUrl/uv')
        .replace(queryParameters: {'fcmToken': fcmToken});

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener datos UV (status ${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint(response.body);
    final parsed = UvResponse.fromJson(json);

    if (!parsed.success) {
      throw Exception(parsed.message);
    }

    return parsed;
  }
}
