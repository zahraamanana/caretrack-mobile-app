import '../config/api_config.dart';
import '../config/firebase_project_config.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';
import 'api_service.dart';
import 'firebase_auth_service.dart';

class AuthService {
  AuthService({
    ApiService? apiService,
    FirebaseAuthService? firebaseAuthService,
  }) : _apiService = apiService ?? ApiService.instance,
       _firebaseAuthService =
           firebaseAuthService ?? FirebaseAuthService.instance;

  static final AuthService instance = AuthService();

  final ApiService _apiService;
  final FirebaseAuthService _firebaseAuthService;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (FirebaseProjectConfig.shouldUseFirebaseAuth) {
      return _firebaseAuthService.signIn(
        email: email,
        password: password,
      );
    }

    if (ApiConfig.useMockAuth || !ApiConfig.hasConfiguredBaseUrl) {
      return _mockSignIn(email: email, password: password);
    }

    final response = await _apiService.post(
      ApiConfig.loginEndpoint,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    return AuthResult(
      message: _messageFromResponse(response) ?? 'Login successful.',
      token: _tokenFromResponse(response),
      user: _userFromResponse(response),
    );
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (FirebaseProjectConfig.shouldUseFirebaseAuth) {
      return _firebaseAuthService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
    }

    throw const ApiException(
      'Create Account is only available after Firebase Auth is enabled.',
    );
  }

  Future<void> signOut() async {
    if (FirebaseProjectConfig.shouldUseFirebaseAuth) {
      await _firebaseAuthService.signOut();
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (FirebaseProjectConfig.shouldUseFirebaseAuth) {
      await _firebaseAuthService.sendPasswordResetEmail(email: email);
      return;
    }

    throw const ApiException(
      'Password reset is only available when Firebase Auth is enabled.',
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
      user: UserProfile(
        id: 'mock-nurse',
        name: 'Demo Nurse',
        email: email.trim(),
      ),
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

  UserProfile? _userFromResponse(Map<String, dynamic> response) {
    final directUser = response['user'];
    if (directUser is Map<String, dynamic>) return UserProfile.fromMap(directUser);

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        return UserProfile.fromMap(nestedUser);
      }
      if (data.containsKey('email') || data.containsKey('uid') || data.containsKey('id')) {
        return UserProfile.fromMap(data);
      }
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
