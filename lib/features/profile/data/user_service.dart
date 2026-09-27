import 'dart:convert';

import 'package:app/core/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.firstName,
    required this.lastName,
    this.registeredAt,
    this.skinTypeId,
  });

  final int id;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final DateTime? registeredAt;
  final int? skinTypeId;

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firebaseUid: json['firebaseUid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'] as String)
          : null,
      skinTypeId: json['skinType'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firebaseUid': firebaseUid,
    'firstName': firstName,
    'lastName': lastName,
    'registeredAt': registeredAt?.toIso8601String(),
    'skinType': skinTypeId,
  };

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    int? skinTypeId,
  }) => UserProfile(
    id: id,
    firebaseUid: firebaseUid,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    registeredAt: registeredAt,
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
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    int? skinTypeId,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (skinTypeId != null) 'skinType': skinTypeId,
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
