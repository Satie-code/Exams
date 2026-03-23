import 'dart:convert';

import 'package:exams_frontend/models/student_exam.dart';
import 'package:http/http.dart' as http;

class StudentApiService {
  StudentApiService({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client;

  final String baseUrl;
  final String accessToken;
  final http.Client? _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  http.Client get _httpClient => _client ?? http.Client();

  Future<List<StudentExam>> fetchAssignedExams() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/student/exams'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final examsJson = payload['exams'] as List<dynamic>;

    return examsJson
        .map((item) => StudentExam.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudentExam> fetchSeating(int examId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/student/seating?exam_id=$examId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return StudentExam.fromJson(payload);
  }

  String _extractMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }
}
