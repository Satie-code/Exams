import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApiService {
  AdminApiService({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client;

  final String baseUrl;
  final String accessToken;
  final http.Client? _client;

  http.Client get _httpClient => _client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> resolveSOS(int requestId) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl/admin/sos/$requestId/resolve'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve SOS: ${response.statusCode}');
    }

    return true;
  }

  Future<bool> approveDutySwap({
    required int swapRequestId,
    required bool approved,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl/admin/swap/approve'),
      headers: _headers,
      body: jsonEncode({
        'swap_request_id': swapRequestId,
        'approved': approved,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process duty swap: ${response.statusCode}');
    }

    return true;
  }
}
