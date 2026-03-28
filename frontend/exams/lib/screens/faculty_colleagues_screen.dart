import 'package:flutter/material.dart';
import 'package:exams_frontend/screens/faculty_duties_screen.dart';
import 'package:exams_frontend/screens/faculty_swaps_screen.dart';
import 'package:exams_frontend/screens/faculty_settings_screen.dart';

class FacultyColleaguesScreen extends StatelessWidget {
  const FacultyColleaguesScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  void _onBottomNavTapped(BuildContext context, int index) {
    if (index == 2) return; // Already on colleagues

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = FacultyDutiesScreen(
          accessToken: accessToken,
          apiBaseUrl: apiBaseUrl,
        );
        break;
      case 1:
        nextScreen = FacultySwapsScreen(
          accessToken: accessToken,
          apiBaseUrl: apiBaseUrl,
        );
        break;
      case 3:
      default:
        nextScreen = FacultySettingsScreen(
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
    // Premium Mock Data
    final colleagues = [
      {'name': 'Dr. Sharma', 'dept': 'Computer Science', 'avatar': 'S'},
      {'name': 'Prof. Patel', 'dept': 'Mathematics', 'avatar': 'P'},
      {'name': 'Dr. Iyer', 'dept': 'Physics', 'avatar': 'I'},
      {'name': 'Prof. Gupta', 'dept': 'Chemistry', 'avatar': 'G'},
      {'name': 'Dr. Reddy', 'dept': 'Electronics', 'avatar': 'R'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Department Directory', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: colleagues.length,
        itemBuilder: (context, index) {
          final p = colleagues[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: const Color(0xFF3157C8),
                radius: 24,
                child: Text(p['avatar']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Text(p['dept']!),
              trailing: IconButton(
                icon: const Icon(Icons.message_rounded, color: Color(0xFF97A5BE)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Messaging ${p['name']}...')),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFF3157C8),
        unselectedItemColor: const Color(0xFF97A5BE),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'My Swaps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Colleagues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
    );
  }
}
