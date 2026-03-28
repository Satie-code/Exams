import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.role,
  });

  final String accessToken;
  final String role;
}

class AuthApiService {
  AuthApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client;

  final String baseUrl;
  final http.Client? _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  http.Client get _httpClient => _client ?? http.Client();

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: 'access_token', value: session.accessToken);
    await _storage.write(key: 'user_role', value: session.role);
  }

  Future<AuthSession?> loadSession() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'user_role');
    if (token != null && role != null && token.isNotEmpty) {
      return AuthSession(accessToken: token, role: role);
    }
    return null;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user_role');
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = payload['access_token'] as String?;
    final role = payload['role'] as String?;

    if (accessToken == null ||
        accessToken.isEmpty ||
        role == null ||
        role.isEmpty) {
      throw Exception('Invalid login response received from the server.');
    }

    return AuthSession(
      accessToken: accessToken,
      role: role,
    );
  }

  String _extractMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Authentication failed';
    } catch (_) {
      return 'Authentication failed';
    }
  }
}
