import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses faculty duties from the API response', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/faculty/duties');
      return http.Response(
        '''
        {
          "duties": [
            {
              "duty_id": 3,
              "exam_id": 12,
              "subject": "Mathematics",
              "date": "2026-04-10",
              "time": "09:00 AM",
              "room": "A-101",
              "role": "INVIGILATOR",
              "status": "CONFIRMED"
            }
          ]
        }
        ''',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = FacultyApiService(
      baseUrl: 'http://localhost:5000',
      accessToken: 'token',
      client: mockClient,
    );

    final duties = await service.fetchDuties();

    expect(duties, hasLength(1));
    expect(duties.first.subject, 'Mathematics');
    expect(duties.first.status, 'CONFIRMED');
  });

  test('submits a swap request successfully', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/faculty/duty/swap');
      expect(request.method, 'POST');
      expect(request.body.contains('"requester_duty_id":3'), isTrue);
      expect(request.body.contains('"target_duty_id":8'), isTrue);

      return http.Response(
        '{"message":"Duty swap requested successfully"}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = FacultyApiService(
      baseUrl: 'http://localhost:5000',
      accessToken: 'token',
      client: mockClient,
    );

    await service.requestSwap(
      requesterDutyId: 3,
      targetDutyId: 8,
    );
  });

  test('submits a bundle scan with bundle_id', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/bundle/scan');
      expect(request.method, 'POST');
      expect(request.body.contains('"duty_id":5'), isTrue);
      expect(request.body.contains('"bundle_id":"BND-204"'), isTrue);

      return http.Response(
        '{"message":"Bundle scanned successfully"}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = FacultyApiService(
      baseUrl: 'http://localhost:5000',
      accessToken: 'token',
      client: mockClient,
    );

    await service.scanBundle(
      dutyId: 5,
      bundleId: 'BND-204',
    );
  });

  test('submits an SOS request successfully', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/sos');
      expect(request.method, 'POST');
      expect(request.body.contains('"duty_id":5'), isTrue);
      expect(request.body.contains('"message":"URGENT_HELP"'), isTrue);

      return http.Response(
        '{"message":"SOS request submitted","pending_count":2}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = FacultyApiService(
      baseUrl: 'http://localhost:5000',
      accessToken: 'token',
      client: mockClient,
    );

    await service.requestSOS(
      dutyId: 5,
      message: 'URGENT_HELP',
    );
  });

  test('submits a post-exam report successfully', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/report');
      expect(request.method, 'POST');
      expect(request.body.contains('"duty_id":5'), isTrue);
      expect(request.body.contains('"declaration_accepted":true'), isTrue);
      expect(request.body.contains('"total_students_present":58'), isTrue);

      return http.Response(
        '{"message":"Post-exam report submitted successfully"}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = FacultyApiService(
      baseUrl: 'http://localhost:5000',
      accessToken: 'token',
      client: mockClient,
    );

    await service.submitReport(
      dutyId: 5,
      totalStudentsPresent: 58,
      totalAnswerSheetsCollected: 58,
      noIncidents: true,
      incidentDetails: null,
      remarks: 'All materials collected.',
      declarationAccepted: true,
    );
  });
}
