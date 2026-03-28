class AuthResult {
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
  final bool isMock;

  const AuthResult({
    required this.message,
    this.token,
    this.user,
    this.isMock = false,
  });
}
