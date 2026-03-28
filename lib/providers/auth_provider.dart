import 'package:flutter/foundation.dart';

import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
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
    _session = await _sessionService.loadSession();
    _isInitializing = false;
    notifyListeners();
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

  Future<void> signOut() async {
    await _sessionService.clearSession();
    _session = null;
    notifyListeners();
  }
}
