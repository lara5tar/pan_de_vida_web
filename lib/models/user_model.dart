class User {
  final String id;
  final String username;
  final String role; // Puede ser "admin", "employee", etc.

  User({required this.id, required this.username, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role};
  }
}
