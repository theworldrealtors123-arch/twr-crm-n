import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.isActive = true,
    this.permissions = const <String>[],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final List<String> permissions;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final String a = firstName.isNotEmpty ? firstName[0] : '';
    final String b = lastName.isNotEmpty ? lastName[0] : '';
    return '$a$b'.toUpperCase();
  }

  bool get canAssignLeads =>
      role == AppRole.superAdmin ||
      role == AppRole.admin ||
      role == AppRole.salesManager;

  bool get canDeleteLeads => role == AppRole.superAdmin || role == AppRole.admin;

  bool get canManageUsers => role == AppRole.superAdmin || role == AppRole.admin;

  bool hasPermission(String key) => permissions.contains(key);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: json['phone'] as String?,
      role: (json['role'] ?? AppRole.agent) as String,
      isActive: (json['isActive'] ?? true) as bool,
      permissions: (json['permissions'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': isActive,
        'permissions': permissions,
      };
}
