import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/screens/post_exam_report_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReportApiFake implements FacultyApi {
  bool submitCalled = false;

  @override
  Future<List<FacultyDuty>> fetchDuties() async => const [];

  @override
  Future<List<FacultyDuty>> fetchSwapOptions(int dutyId) async => const [];

  @override
  Future<void> requestSwap({
    required int requesterDutyId,
    required int targetDutyId,
  }) async {}

  @override
  Future<void> scanBundle({
    required int dutyId,
    required String bundleId,
  }) async {}

  @override
  Future<void> markAttendance({
    required int dutyId,
    required String studentIdentifier,
  }) async {}

  @override
  Future<void> requestSupplies({
    required int dutyId,
    required String item,
    required int quantity,
    String? note,
  }) async {}

  @override
  Future<void> requestSOS({
    required int dutyId,
    required String message,
  }) async {}

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
    submitCalled = true;
  }

  @override
  Future<void> startWashroomTimer({
    required int dutyId,
    required String studentId,
  }) async {}

  @override
  Future<void> endWashroomTimer({
    required int dutyId,
    required String studentId,
  }) async {}

  @override
  Future<FacultyDashboardActivity> fetchActivity({
    required int dutyId,
  }) async {
    return const FacultyDashboardActivity(
      registeredCount: 0,
      maxCapacity: 0,
      pendingSosCount: 0,
      washroomLogs: [],
      activities: [],
    );
  }
}

void main() {
  const duty = FacultyDuty(
    dutyId: 3,
    examId: 7,
    subject: 'Computer Science Fundamentals',
    date: '2026-04-10',
    time: '09:00 AM - 12:00 PM (3 Hours)',
    room: 'Hall 4B | North Wing',
    role: 'INVIGILATOR',
    status: 'CONFIRMED',
  );

  testWidgets('requires declaration before report submission', (tester) async {
    final api = _ReportApiFake();

    await tester.pumpWidget(
      MaterialApp(
        home: PostExamReportScreen(
          duty: duty,
          api: api,
          registeredCount: 60,
          maxCapacity: 65,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit & Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('Declaration checkbox is required.'), findsOneWidget);
    expect(api.submitCalled, isFalse);
  });

  testWidgets('renders structured report layout', (tester) async {
    final api = _ReportApiFake();

    await tester.pumpWidget(
      MaterialApp(
        home: PostExamReportScreen(
          duty: duty,
          api: api,
          registeredCount: 60,
          maxCapacity: 65,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Post-Exam Report'), findsOneWidget);
    expect(find.text('Attendance & Collection'), findsOneWidget);
    expect(find.text('Irregularities & Incidents'), findsOneWidget);
    expect(find.text('Remarks'), findsOneWidget);
    expect(find.text('Submit & Generate Report'), findsOneWidget);
  });
}
