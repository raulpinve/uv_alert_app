import 'dart:convert';

import 'package:app/core/config/api_config.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/features/profile/data/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UserService {
  UserService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ApiException(401, 'No hay un usuario autenticado.');
    }
    final idToken = await user.getIdToken();
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  ApiException _parseError(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map<String, dynamic>) {
        final rawErrors = data['errors'];
        final fieldErrors = rawErrors is List
            ? rawErrors
                  .whereType<Map>()
                  .map(
                    (e) => FieldError(
                      (e['field'] ?? e['path'] ?? e['param'] ?? '').toString(),
                      (e['message'] ?? e['msg'] ?? '').toString(),
                    ),
                  )
                  .toList()
            : <FieldError>[];

        return ApiException(
          res.statusCode,
          data['message']?.toString() ?? 'Error inesperado (${res.statusCode})',
          type: data['error']?.toString(),
          fieldErrors: fieldErrors,
        );
      }
    } catch (_) {
      // El body no era JSON (por ejemplo, HTML de un proxy o gateway).
    }
    return ApiException(res.statusCode, 'Error inesperado (${res.statusCode})');
  }

  void _check(http.Response res, {Set<int> ok = const {200}}) {
    if (!ok.contains(res.statusCode)) throw _parseError(res);
  }

  Future<UserProfile> fetchProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
    );
    _check(res);
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return UserProfile.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Envía solo los campos que cambian.
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    int? skinTypeId,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (skinTypeId != null) 'skinTypeId': skinTypeId,
    };
    final res = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _check(res);
  }
}
