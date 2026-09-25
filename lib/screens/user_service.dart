// lib/services/user_service.dart
//
// OJO: los endpoints (/users/me) y los nombres de campos son SUPUESTOS.
// Ajústalos a lo que exponga tu backend.
import 'dart:convert';

import 'package:app/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  UserProfile({required this.name, required this.email, this.skinTypeId});

  final String name;
  final String email;
  final int? skinTypeId;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    skinTypeId: json['skinTypeId'] as int?,
  );

  UserProfile copyWith({String? name, int? skinTypeId}) => UserProfile(
    name: name ?? this.name,
    email: email,
    skinTypeId: skinTypeId ?? this.skinTypeId,
  );
}

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
  Future<void> updateProfile({String? name, int? skinTypeId}) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
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
