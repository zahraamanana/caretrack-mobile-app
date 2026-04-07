import 'user_profile.dart';

class AuthResult {
  final String message;
  final String? token;
  final UserProfile? user;
  final bool isMock;

  const AuthResult({
    required this.message,
    this.token,
    this.user,
    this.isMock = false,
  });
}
