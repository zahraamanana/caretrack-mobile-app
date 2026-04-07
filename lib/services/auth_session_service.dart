import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_result.dart';
import '../models/auth_session.dart';
import 'logger_service.dart';

class AuthSessionService {
  AuthSessionService({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static final AuthSessionService instance = AuthSessionService();

  static const String _sessionKey = 'auth_session';
  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<AuthSession?> loadSession() async {
    final rawSession = await _readMigratedSession();
    if (rawSession == null || rawSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final session = AuthSession.fromMap(decoded);
      if (session.token.trim().isEmpty) {
        return null;
      }
      return session;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to decode saved auth session.', error, stackTrace);
      return null;
    }
  }

  Future<String?> loadToken() async {
    final session = await loadSession();
    final token = session?.token.trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<AuthSession> saveSession(AuthResult result) async {
    final session = AuthSession(
      token: (result.token ?? 'session-active').trim(),
      user: result.user,
      isMock: result.isMock,
    );

    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toMap()),
    );
    return session;
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
    final prefs = await _preferencesLoader();
    await prefs.remove(_sessionKey);
  }

  Future<String?> _readMigratedSession() async {
    final secureValue = await _secureStorage.read(key: _sessionKey);
    if (secureValue != null && secureValue.trim().isNotEmpty) {
      return secureValue;
    }

    final prefs = await _preferencesLoader();
    final legacyValue = prefs.getString(_sessionKey);
    if (legacyValue == null || legacyValue.trim().isEmpty) {
      return null;
    }

    await _secureStorage.write(key: _sessionKey, value: legacyValue);
    await prefs.remove(_sessionKey);
    return legacyValue;
  }
}
