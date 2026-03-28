import 'package:flutter/material.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:exams_frontend/screens/faculty_duties_screen.dart';
import 'package:exams_frontend/screens/faculty_colleagues_screen.dart';
import 'package:exams_frontend/screens/faculty_settings_screen.dart';

class FacultySwapsScreen extends StatefulWidget {
  const FacultySwapsScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  @override
  State<FacultySwapsScreen> createState() => _FacultySwapsScreenState();
}

class _FacultySwapsScreenState extends State<FacultySwapsScreen> {
  bool _isLoading = true;
  List<FacultyDuty> _myDuties = [];
  String? _error;
  late final FacultyApi _api;

  @override
  void initState() {
    super.initState();
    _api = FacultyApiService(
      baseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );
    _loadDuties();
  }

  Future<void> _loadDuties() async {
    try {
      final duties = await _api.fetchDuties();
      if (!mounted) return;
      
      setState(() {
        _myDuties = duties.where((d) => d.status == 'CONFIRMED').toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSwapDetailed(FacultyDuty duty) async {
    try {
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final options = await _api.fetchSwapOptions(duty.dutyId);
      
      if (!mounted) return;
      Navigator.pop(context); // close loader

      if (options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available colleagues found for a swap right now.')),
        );
        return;
      }

      final targetDuty = await showDialog<FacultyDuty>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select a swap option'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text('${option.subject} as ${option.role}'),
                    subtitle: Text('${option.date} \u2022 ${option.time} \u2022 Room ${option.room}'),
                    trailing: const Icon(Icons.swap_horiz_rounded),
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          );
        },
      );

      if (targetDuty != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await _api.requestSwap(
          requesterDutyId: duty.dutyId,
          targetDutyId: targetDuty.dutyId,
        );

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap request submitted successfully!')),
        );
        _loadDuties();
      }

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close potential loaders
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) return; // Already on swaps

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = FacultyDutiesScreen(
          accessToken: widget.accessToken,
          apiBaseUrl: widget.apiBaseUrl,
        );
        break;
      case 2:
        nextScreen = FacultyColleaguesScreen(
          accessToken: widget.accessToken,
          apiBaseUrl: widget.apiBaseUrl,
        );
        break;
      case 3:
      default:
        nextScreen = FacultySettingsScreen(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('My Duty Swaps', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Failed: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDuties, child: const Text('Retry'))
                    ],
                  ),
                )
              : _myDuties.isEmpty
                  ? const Center(child: Text('No active duties available to swap.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _myDuties.length,
                      itemBuilder: (context, index) {
                        final duty = _myDuties[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  duty.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('${duty.date} at ${duty.time}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('Room ${duty.room} as ${duty.role}'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _requestSwapDetailed(duty),
                                    icon: const Icon(Icons.swap_calls_rounded),
                                    label: const Text('Find Swap Replacement'),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF3157C8)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
