import 'package:flutter/foundation.dart';

import '../config/firebase_project_config.dart';
import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/auth_session_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/logger_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    AuthSessionService? sessionService,
    FirebaseAuthService? firebaseAuthService,
  }) : _authService = authService ?? AuthService.instance,
       _sessionService = sessionService ?? AuthSessionService.instance,
       _firebaseAuthService =
           firebaseAuthService ?? FirebaseAuthService.instance;

  final AuthService _authService;
  final AuthSessionService _sessionService;
  final FirebaseAuthService _firebaseAuthService;

  AuthSession? _session;
  bool _isInitializing = true;
  bool _isSubmitting = false;

  AuthSession? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _session != null;

  Future<void> initialize() async {
    try {
      if (FirebaseProjectConfig.shouldUseFirebaseAuth) {
        final restored = await _firebaseAuthService.restoreSession();
        if (restored != null) {
          _session = await _sessionService.saveSession(restored);
        } else {
          await _sessionService.clearSession();
          _session = null;
        }
      } else {
        _session = await _sessionService.loadSession();
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize auth session.', error, stackTrace);
      await _sessionService.clearSession();
      _session = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );
      _session = await _sessionService.saveSession(result);
      notifyListeners();
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      _session = await _sessionService.saveSession(result);
      notifyListeners();
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _sessionService.clearSession();
    _session = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _authService.sendPasswordResetEmail(email: email);
  }
}
