import 'dart:convert';

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

  http.Client get _httpClient => _client ?? http.Client();

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
