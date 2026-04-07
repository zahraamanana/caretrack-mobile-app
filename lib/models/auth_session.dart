import 'user_profile.dart';

class AuthSession {
  final String token;
  final UserProfile? user;
  final bool isMock;

  const AuthSession({
    required this.token,
    this.user,
    this.isMock = false,
  });

  String? get userName {
    final value = user?.name;
    return value != null && value.trim().isNotEmpty ? value.trim() : null;
  }

  String? get userEmail {
    final value = user?.email;
    return value != null && value.trim().isNotEmpty ? value.trim() : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'user': user?.toMap(),
      'isMock': isMock,
    };
  }

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    return AuthSession(
      token: map['token'] as String? ?? '',
      user: map['user'] is Map
          ? UserProfile.fromMap(Map<String, dynamic>.from(map['user'] as Map))
          : null,
      isMock: map['isMock'] as bool? ?? false,
    );
  }
}
