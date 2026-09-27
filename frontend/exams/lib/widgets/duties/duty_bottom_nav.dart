import 'package:exams_frontend/screens/faculty_colleagues_screen.dart';
import 'package:exams_frontend/screens/faculty_settings_screen.dart';
import 'package:exams_frontend/screens/faculty_swaps_screen.dart';
import 'package:flutter/material.dart';

class FacultyBottomNav extends StatelessWidget {
  const FacultyBottomNav({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
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
      onTap: (index) {
        if (index == 0) return;

        Widget nextScreen;
        switch (index) {
          case 1:
            nextScreen = FacultySwapsScreen(
              accessToken: accessToken,
              apiBaseUrl: apiBaseUrl,
            );
            break;
          case 2:
            nextScreen = FacultyColleaguesScreen(
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
      },
    );
  }
}
