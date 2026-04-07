import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_session_service.dart';
import 'logger_service.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService.instance;

  static final ApiService instance = ApiService._();

  final http.Client _client;
  final AuthSessionService _authSessionService;

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    if (!ApiConfig.hasConfiguredBaseUrl) {
      throw const ApiException(
        'API base URL is not configured yet. Update ApiConfig before calling the real backend.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final requestHeaders = await _buildHeaders(
      headers: headers,
      requiresAuth: requiresAuth,
      includeJsonContentType: false,
    );
    final response = await _sendRequest(
      () => _client.get(
        uri,
        headers: requestHeaders,
      ),
    );

    final decodedBody = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw ApiException(
      _extractMessage(decodedBody) ??
          'Request failed with status code ${response.statusCode}.',
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendJson(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendJson(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendJson(
      method: 'DELETE',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required bool requiresAuth,
  }) async {
    if (!ApiConfig.hasConfiguredBaseUrl) {
      throw const ApiException(
        'API base URL is not configured yet. Update ApiConfig before calling the real backend.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    late final http.Response response;
    final requestHeaders = await _buildHeaders(
      headers: headers,
      requiresAuth: requiresAuth,
      includeJsonContentType: true,
    );
    final encodedBody = jsonEncode(body ?? const <String, dynamic>{});

    switch (method) {
      case 'POST':
        response = await _sendRequest(
          () => _client.post(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          ),
        );
        break;
      case 'PUT':
        response = await _sendRequest(
          () => _client.put(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          ),
        );
        break;
      case 'DELETE':
        response = await _sendRequest(
          () => _client.delete(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          ),
        );
        break;
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }

    final dynamic decodedBody = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }
      return {'data': decodedBody};
    }

    throw ApiException(
      _extractMessage(decodedBody) ??
          'Request failed with status code ${response.statusCode}.',
    );
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
    required bool requiresAuth,
    required bool includeJsonContentType,
  }) async {
    final builtHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    if (includeJsonContentType) {
      builtHeaders.putIfAbsent('Content-Type', () => 'application/json');
    }

    if (requiresAuth && !builtHeaders.containsKey(ApiConfig.authHeaderName)) {
      final token = await _authSessionService.loadToken();
      if (token != null && token.isNotEmpty) {
        builtHeaders[ApiConfig.authHeaderName] =
            '${ApiConfig.authTokenPrefix} $token';
      }
    }

    return builtHeaders;
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(
        const Duration(seconds: ApiConfig.requestTimeoutSeconds),
      );
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;

    try {
      return jsonDecode(body);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to decode API response body as JSON.', error, stackTrace);
      return body;
    }
  }

  String? _extractMessage(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      final message = decodedBody['message'] ??
          decodedBody['error'] ??
          decodedBody['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (decodedBody is String && decodedBody.trim().isNotEmpty) {
      return decodedBody;
    }

    return null;
  }
}
