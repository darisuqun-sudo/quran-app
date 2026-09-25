import 'dart:convert';

enum UserRole {
  visitor,
  member,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final int dailyGoalMinutes;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.dailyGoalMinutes = 15,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? 'user_1',
      name: map['name'] as String? ?? 'ئەزا',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (map['role'] as String? ?? 'member'),
        orElse: () => UserRole.member,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      dailyGoalMinutes: map['dailyGoalMinutes'] as int? ?? 15,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    int? dailyGoalMinutes,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}
