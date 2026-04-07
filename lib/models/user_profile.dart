class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'nurse',
  });

  bool get isValid => id.trim().isNotEmpty && email.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] ?? map['uid'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      role: (map['role'] ?? 'nurse').toString().trim(),
    );
  }
}
