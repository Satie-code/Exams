import 'package:flutter/material.dart';
import 'package:exams_frontend/screens/faculty_duties_screen.dart';
import 'package:exams_frontend/screens/faculty_swaps_screen.dart';
import 'package:exams_frontend/screens/faculty_colleagues_screen.dart';
import 'package:exams_frontend/screens/login_screen.dart';
import 'package:exams_frontend/services/auth_api_service.dart';

class FacultySettingsScreen extends StatefulWidget {
  const FacultySettingsScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  @override
  State<FacultySettingsScreen> createState() => _FacultySettingsScreenState();
}

class _FacultySettingsScreenState extends State<FacultySettingsScreen> {
  bool _notificationsEnabled = true;

  void _onBottomNavTapped(BuildContext context, int index) {
    if (index == 3) return; // Already on settings

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = FacultyDutiesScreen(
          accessToken: widget.accessToken,
          apiBaseUrl: widget.apiBaseUrl,
        );
        break;
      case 1:
        nextScreen = FacultySwapsScreen(
          accessToken: widget.accessToken,
          apiBaseUrl: widget.apiBaseUrl,
        );
        break;
      case 2:
      default:
        nextScreen = FacultyColleaguesScreen(
          accessToken: widget.accessToken,
          apiBaseUrl: widget.apiBaseUrl,
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

  Future<void> _handleLogout() async {
    final authApi = AuthApiService(baseUrl: widget.apiBaseUrl);
    await authApi.clearSession();
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          apiBaseUrl: widget.apiBaseUrl,
          onLogin: (session) {
            // Restart basically
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Settings & Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE2E8F0),
                    foregroundColor: Color(0xFF3157C8),
                    radius: 36,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FACULTY',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Department of Engineering',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Alerts for swaps and emergencies'),
                  value: _notificationsEnabled,
                  activeThumbColor: const Color(0xFF3157C8),
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                  },
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  onTap: () {},
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  onTap: () {},
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to log out of the portal?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE92822),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
