import 'package:exams_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots the student flow from the main app', (tester) async {
    await tester.pumpWidget(
      const ExamsApp(
        accessToken: 'token',
        apiBaseUrl: 'http://localhost:5000',
        userRole: 'STUDENT',
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('boots the faculty flow from the main app', (tester) async {
    await tester.pumpWidget(
      const ExamsApp(
        accessToken: 'token',
        apiBaseUrl: 'http://localhost:5000',
        userRole: 'FACULTY',
      ),
    );
    await tester.pump();

    expect(find.text('Exam Duties'), findsOneWidget);
  });
}
