import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_result.dart';
import '../models/auth_session.dart';

class AuthSessionService {
  AuthSessionService._();

  static final AuthSessionService instance = AuthSessionService._();

  static const String _sessionKey = 'auth_session';

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSession = prefs.getString(_sessionKey);
    if (rawSession == null || rawSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map) return null;
      final session = AuthSession.fromMap(Map<String, dynamic>.from(decoded));
      if (session.token.trim().isEmpty) return null;
      return session;
    } catch (_) {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toMap()));
    return session;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
