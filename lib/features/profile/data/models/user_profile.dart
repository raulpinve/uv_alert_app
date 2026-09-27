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
