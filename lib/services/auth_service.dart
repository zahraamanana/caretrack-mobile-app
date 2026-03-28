import '../config/api_config.dart';
import '../models/auth_result.dart';
import 'api_service.dart';

class AuthService {
  AuthService._({ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  static final AuthService instance = AuthService._();

  final ApiService _apiService;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (ApiConfig.useMockAuth || !ApiConfig.hasConfiguredBaseUrl) {
      return _mockSignIn(email: email, password: password);
    }

    final response = await _apiService.post(
      ApiConfig.loginEndpoint,
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthResult(
      message: _messageFromResponse(response) ?? 'Login successful.',
      token: _tokenFromResponse(response),
      user: _userFromResponse(response),
      isMock: false,
    );
  }

  Future<AuthResult> _mockSignIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const ApiException('Email and password are required.');
    }

    return AuthResult(
      message: 'Signed in with demo auth mode.',
      token: 'mock-token',
      user: {
        'name': 'Demo Nurse',
        'email': email.trim(),
      },
      isMock: true,
    );
  }

  String? _tokenFromResponse(Map<String, dynamic> response) {
    final directToken = response['token'] ?? response['access_token'];
    if (directToken is String && directToken.isNotEmpty) return directToken;

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedToken = data['token'] ?? data['access_token'];
      if (nestedToken is String && nestedToken.isNotEmpty) {
        return nestedToken;
      }
    }

    return null;
  }

  Map<String, dynamic>? _userFromResponse(Map<String, dynamic> response) {
    final directUser = response['user'];
    if (directUser is Map<String, dynamic>) return directUser;

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      return data;
    }

    return null;
  }

  String? _messageFromResponse(Map<String, dynamic> response) {
    final message = response['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedMessage = data['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage;
      }
    }

    return null;
  }
}
