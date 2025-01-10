import 'package:equatable/equatable.dart';

enum Role {
  admin,
  moderator,
  employee,
  customer;

  static Role fromString(String role) {
    for (final value in values) {
      if ('$value' == role) return value;
    }

    throw UnsupportedError('Invalid Role ($role)');
  }

  @override
  String toString() => name;
}

class User extends Equatable {
  final String? id;
  final String name;
  final String email;
  final String password;
  final Role role;
  final bool active;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.active = true,
  });

  User.copyWith(
    User user, {
    String? id,
    String? name,
    String? email,
    String? password,
    Role? role,
    bool? active,
  })  : id = id ?? user.id,
        name = name ?? user.name,
        email = email ?? user.email,
        password = password ?? user.password,
        role = role ?? user.role,
        active = active ?? user.active;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    Role? role,
    bool? active,
  }) =>
      User.copyWith(
        this,
        id: id,
        name: name,
        email: email,
        password: password,
        role: role,
        active: active,
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role.toString(),
      'active': active,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      role: Role.fromString(json['role']),
      active: json['active'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        password,
        role,
        active,
      ];
}
