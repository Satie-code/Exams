import 'package:flutter/material.dart';
import 'package:exams_frontend/screens/find_my_seat_screen.dart';
import 'package:exams_frontend/screens/student_profile_screen.dart';

class StudentScheduleScreen extends StatelessWidget {
  const StudentScheduleScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  void _onBottomNavTapped(BuildContext context, int index) {
    if (index == 1) return; // Already on Schedule

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = FindMySeatScreen(
          accessToken: accessToken,
          apiBaseUrl: apiBaseUrl,
        );
        break;
      case 2:
      default:
        nextScreen = StudentProfileScreen(
          accessToken: accessToken,
          apiBaseUrl: apiBaseUrl,
        );
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = [
      {'date': '03/29/2026', 'subject': 'MATH101 - Calculus I', 'time': '10:00 AM', 'room': 'Hall A'},
      {'date': '04/02/2026', 'subject': 'PHYS201 - Quantum Mechanics', 'time': '02:00 PM', 'room': 'Lab 4'},
      {'date': '04/05/2026', 'subject': 'ENG105 - Literature', 'time': '09:00 AM', 'room': 'Room 102'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('My Exam Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final exam = schedule[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam['subject']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${exam['date']} \u2022 ${exam['time']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Assigned Room: ${exam['room']}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF4560BD),
        unselectedItemColor: const Color(0xFF97A5BE),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Locator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
    );
  }
}
