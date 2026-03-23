import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/models/washroom_log.dart';
import 'package:exams_frontend/screens/faculty_dashboard_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DashboardApiSuccessFake implements FacultyApi {
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
  }) async {}

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

class _DashboardApiErrorFake extends _DashboardApiSuccessFake {
  @override
  Future<void> scanBundle({
    required int dutyId,
    required String bundleId,
  }) async {
    throw Exception('Wrong room for this bundle');
  }
}

class _DashboardApiWashroomFake extends _DashboardApiSuccessFake {
  @override
  Future<FacultyDashboardActivity> fetchActivity({
    required int dutyId,
  }) async {
    return FacultyDashboardActivity(
      registeredCount: 0,
      maxCapacity: 0,
      pendingSosCount: 0,
      washroomLogs: [
        WashroomLog(
          logId: 4,
          studentId: 'STU-42',
          startTime: DateTime.now().subtract(const Duration(minutes: 6)),
          endTime: null,
          durationSeconds: 360,
          status: 'WARNING',
          state: 'yellow',
        ),
      ],
      activities: const [],
    );
  }
}

class _DashboardApiPendingSosFake extends _DashboardApiSuccessFake {
  @override
  Future<FacultyDashboardActivity> fetchActivity({
    required int dutyId,
  }) async {
    return const FacultyDashboardActivity(
      registeredCount: 0,
      maxCapacity: 0,
      pendingSosCount: 2,
      washroomLogs: [],
      activities: [],
    );
  }
}

void main() {
  const duty = FacultyDuty(
    dutyId: 3,
    examId: 7,
    subject: 'Mathematics',
    date: '2026-04-10',
    time: '09:00 AM - 12:00 PM',
    room: 'A-101',
    role: 'INVIGILATOR',
    status: 'CONFIRMED',
  );

  const completedDuty = FacultyDuty(
    dutyId: 4,
    examId: 8,
    subject: 'Computer Science Fundamentals',
    date: '2020-04-10',
    time: '09:00 AM - 12:00 PM',
    room: 'Hall 4B',
    role: 'INVIGILATOR',
    status: 'CONFIRMED',
  );

  testWidgets('shows a green snackbar after a successful bundle scan',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDashboardScreen(
          duty: duty,
          api: _DashboardApiSuccessFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Materials'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'BND-100');
    await tester.tap(find.text('Confirm Scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(find.text('Bundle scanned successfully.'), findsOneWidget);
    expect(snackBar.backgroundColor, const Color(0xFF25B468));
  });

  testWidgets('shows a red snackbar when bundle scan fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDashboardScreen(
          duty: duty,
          api: _DashboardApiErrorFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Materials'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'BND-999');
    await tester.tap(find.text('Confirm Scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(find.text('Wrong room for this bundle'), findsOneWidget);
    expect(snackBar.backgroundColor, const Color(0xFFE55656));
  });

  testWidgets('renders live washroom cards with student ID and status',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDashboardScreen(
          duty: duty,
          api: _DashboardApiWashroomFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student ID: STU-42'), findsOneWidget);
    expect(find.textContaining('Started'), findsOneWidget);
    expect(find.text('REMAINING'), findsOneWidget);
  });

  testWidgets('shows SOS actions with pending count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDashboardScreen(
          duty: duty,
          api: _DashboardApiPendingSosFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 Pending'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Answer Sheets'), findsOneWidget);
    expect(find.text('Stationery'), findsOneWidget);
    expect(find.text('Urgent Help'), findsOneWidget);
  });

  testWidgets('shows post-exam report action on the dashboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDashboardScreen(
          duty: completedDuty,
          api: _DashboardApiSuccessFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Post-Exam Report'), findsOneWidget);
  });
}
