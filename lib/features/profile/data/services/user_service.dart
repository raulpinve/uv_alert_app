import 'dart:convert';

import 'package:app/core/config/api_config.dart';
import 'package:app/features/profile/data/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UserService {
  UserService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');
    final idToken = await user.getIdToken();
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  Future<UserProfile> fetchProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al obtener el perfil (status ${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
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
    if (res.statusCode != 200) {
      throw Exception('No se pudo guardar (status ${res.statusCode})');
    }
  }
}
