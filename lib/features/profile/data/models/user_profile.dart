class SkinType {
  SkinType({
    required this.id,
    required this.scale,
    required this.name,
    required this.description,
    required this.sensitivityFactor,
  });

  final int id;
  final String scale;
  final String name;
  final String description;
  final num sensitivityFactor;

  factory SkinType.fromJson(Map<String, dynamic> json) {
    return SkinType(
      id: json['id'] as int,
      scale: json['scale'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sensitivityFactor: json['sensitivityFactor'] as num? ?? 0,
    );
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.firstName,
    required this.lastName,
    this.registeredAt,
    this.skinType,
  });

  final int id;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final DateTime? registeredAt;
  final SkinType? skinType;

  String get fullName => '$firstName $lastName';
  int? get skinTypeId =>
      skinType?.id; // para seguir mandando el id al hacer PATCH

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firebaseUid: json['firebaseUid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'] as String)
          : null,
      skinType: json['skinType'] != null
          ? SkinType.fromJson(json['skinType'] as Map<String, dynamic>)
          : null,
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    SkinType? skinType,
  }) => UserProfile(
    id: id,
    firebaseUid: firebaseUid,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    registeredAt: registeredAt,
    skinType: skinType ?? this.skinType,
  );
}
