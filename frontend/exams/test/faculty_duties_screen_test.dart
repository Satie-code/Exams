import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/screens/faculty_duties_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFacultyApi implements FacultyApi {
  _FakeFacultyApi({
    required this.duties,
  });

  final List<FacultyDuty> duties;

  @override
  Future<List<FacultyDuty>> fetchDuties() async => duties;

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

void main() {
  testWidgets('renders faculty duty cards and status badges', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = _FakeFacultyApi(
      duties: const [
        FacultyDuty(
          dutyId: 1,
          examId: 11,
          subject: 'Physics',
          date: '2027-04-05',
          time: '10:00 AM',
          room: 'B-201',
          role: 'INVIGILATOR',
          status: 'CONFIRMED',
        ),
        FacultyDuty(
          dutyId: 2,
          examId: 12,
          subject: 'Chemistry',
          date: '2027-04-06',
          time: '02:00 PM',
          room: 'C-102',
          role: 'LEAD',
          status: 'PENDING_SWAP',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FacultyDutiesScreen(
          accessToken: 'token',
          apiBaseUrl: 'http://localhost:5000',
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exam Duties'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Chemistry'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('PENDING AGREEMENT'), findsOneWidget);
    expect(find.text('Request Swap'), findsOneWidget);
    expect(find.text('Cancel Request'), findsOneWidget);
    expect(find.text('Faculty coordination desk'), findsOneWidget);
  });
}
