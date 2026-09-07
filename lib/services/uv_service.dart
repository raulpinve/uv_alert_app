import 'dart:convert';

import 'package:app/config/api_config.dart';
import 'package:app/models/uv.dart';
import 'package:http/http.dart' as http;

class UvService {
  UvService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<UvResponse> fetchUv({required String fcmToken}) async {
    final uri = Uri.parse('$baseUrl/uv')
        .replace(queryParameters: {'fcm_token': fcmToken});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener datos UV (status ${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final parsed = UvResponse.fromJson(json);

    if (!parsed.success) {
      throw Exception(parsed.message);
    }

    return parsed;
  }
}
