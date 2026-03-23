import 'dart:convert';

import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:http/http.dart' as http;

abstract class FacultyApi {
  Future<List<FacultyDuty>> fetchDuties();
  Future<List<FacultyDuty>> fetchSwapOptions(int dutyId);
  Future<void> requestSwap({
    required int requesterDutyId,
    required int targetDutyId,
  });
  Future<void> scanBundle({
    required int dutyId,
    required String bundleId,
  });
  Future<void> markAttendance({
    required int dutyId,
    required String studentIdentifier,
  });
  Future<void> requestSupplies({
    required int dutyId,
    required String item,
    required int quantity,
    String? note,
  });
  Future<void> requestSOS({
    required int dutyId,
    required String message,
  });
  Future<void> submitReport({
    required int dutyId,
    required int totalStudentsPresent,
    required int totalAnswerSheetsCollected,
    required bool noIncidents,
    String? incidentDetails,
    String? remarks,
    required bool declarationAccepted,
  });
  Future<void> startWashroomTimer({
    required int dutyId,
    required String studentId,
  });
  Future<void> endWashroomTimer({
    required int dutyId,
    required String studentId,
  });
  Future<FacultyDashboardActivity> fetchActivity({
    required int dutyId,
  });
}

class FacultyApiService implements FacultyApi {
  FacultyApiService({
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

  @override
  Future<List<FacultyDuty>> fetchDuties() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/faculty/duties'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final dutiesJson = payload['duties'] as List<dynamic>;

    return dutiesJson
        .map((item) => FacultyDuty.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FacultyDuty>> fetchSwapOptions(int dutyId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/faculty/duty/swap-options?duty_id=$dutyId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final optionsJson = payload['swap_options'] as List<dynamic>;

    return optionsJson
        .map((item) => FacultyDuty.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> requestSwap({
    required int requesterDutyId,
    required int targetDutyId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/faculty/duty/swap'),
      headers: _headers,
      body: jsonEncode({
        'requester_duty_id': requesterDutyId,
        'target_duty_id': targetDutyId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response.body));
    }
  }

  @override
  Future<void> scanBundle({
    required int dutyId,
    required String bundleId,
  }) async {
    await _post(
      path: '/bundle/scan',
      body: {
        'duty_id': dutyId,
        'bundle_id': bundleId,
      },
    );
  }

  @override
  Future<void> markAttendance({
    required int dutyId,
    required String studentIdentifier,
  }) async {
    await _post(
      path: '/attendance',
      body: {
        'duty_id': dutyId,
        'student_identifier': studentIdentifier,
      },
    );
  }

  @override
  Future<void> requestSupplies({
    required int dutyId,
    required String item,
    required int quantity,
    String? note,
  }) async {
    await _post(
      path: '/supplies/request',
      body: {
        'duty_id': dutyId,
        'item': item,
        'quantity': quantity,
        'note': note,
      },
    );
  }

  @override
  Future<void> requestSOS({
    required int dutyId,
    required String message,
  }) async {
    await _post(
      path: '/sos',
      body: {
        'duty_id': dutyId,
        'message': message,
      },
    );
  }

  @override
  Future<void> submitReport({
    required int dutyId,
    required int totalStudentsPresent,
    required int totalAnswerSheetsCollected,
    required bool noIncidents,
    String? incidentDetails,
    String? remarks,
    required bool declarationAccepted,
  }) async {
    await _post(
      path: '/report',
      body: {
        'duty_id': dutyId,
        'total_students_present': totalStudentsPresent,
        'total_answer_sheets_collected': totalAnswerSheetsCollected,
        'no_incidents': noIncidents,
        'incident_details': incidentDetails,
        'remarks': remarks,
        'declaration_accepted': declarationAccepted,
      },
    );
  }

  @override
  Future<void> startWashroomTimer({
    required int dutyId,
    required String studentId,
  }) async {
    await _post(
      path: '/washroom/start',
      body: {
        'duty_id': dutyId,
        'student_id': studentId,
      },
    );
  }

  @override
  Future<void> endWashroomTimer({
    required int dutyId,
    required String studentId,
  }) async {
    await _post(
      path: '/washroom/end',
      body: {
        'duty_id': dutyId,
        'student_id': studentId,
      },
    );
  }

  @override
  Future<FacultyDashboardActivity> fetchActivity({
    required int dutyId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/activity?duty_id=$dutyId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return FacultyDashboardActivity.fromJson(payload);
  }

  Future<void> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractMessage(response.body));
    }
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
