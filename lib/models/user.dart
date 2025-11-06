class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final int roleId;
  final String? profilePicture;
  final DateTime? birthdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roleId,
    this.profilePicture,
    this.birthdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      roleId: json['role_id'] ?? '',
      profilePicture: json['profile_picture'],
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'role_id': roleId,
    'profile_picture': profilePicture,
    'birthdate': birthdate?.toIso8601String(),
  };
}