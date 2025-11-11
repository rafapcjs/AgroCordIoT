class UserModel {
  final String id;
  final String name;
  final String lastName;
  final String phone;
  final String email;
  final String username;
  final String role;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      'role': role,
    };
  }
}

class CreateUserModel {
  final String name;
  final String lastName;
  final String phone;
  final String email;
  final String username;
  final String password;
  final String role;

  CreateUserModel({
    required this.name,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}