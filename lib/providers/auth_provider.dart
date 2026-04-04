import 'package:flutter/foundation.dart';

import '../config/firebase_project_config.dart';
import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_session_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    AuthSessionService? sessionService,
  }) : _authService = authService ?? AuthService.instance,
       _sessionService = sessionService ?? AuthSessionService.instance;

  final AuthService _authService;
  final AuthSessionService _sessionService;

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
        final restored = await FirebaseAuthService.instance.restoreSession();
        if (restored != null) {
          _session = await _sessionService.saveSession(restored);
        } else {
          await _sessionService.clearSession();
          _session = null;
        }
      } else {
        _session = await _sessionService.loadSession();
      }
    } catch (_) {
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
}
