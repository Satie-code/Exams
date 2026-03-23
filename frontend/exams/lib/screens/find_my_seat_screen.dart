import 'package:exams_frontend/models/student_exam.dart';
import 'package:exams_frontend/services/student_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FindMySeatScreen extends StatefulWidget {
  const FindMySeatScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  @override
  State<FindMySeatScreen> createState() => _FindMySeatScreenState();
}

class _FindMySeatScreenState extends State<FindMySeatScreen> {
  late final StudentApiService _apiService;
  late Future<List<StudentExam>> _examsFuture;
  final TextEditingController _urnController = TextEditingController();

  DateTime? _selectedDate;
  StudentExam? _selectedExam;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _apiService = StudentApiService(
      baseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );
    _examsFuture = _loadAssignedExams();
  }

  @override
  void dispose() {
    _urnController.dispose();
    super.dispose();
  }

  Future<List<StudentExam>> _loadAssignedExams() {
    if (widget.accessToken.isEmpty) {
      return Future<List<StudentExam>>.error(
        Exception('Missing access token. Please sign in again.'),
      );
    }

    return _apiService.fetchAssignedExams();
  }

  Future<void> _refresh() async {
    setState(() {
      _examsFuture = _loadAssignedExams();
    });

    await _examsFuture;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF4560BD),
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _findSeat(List<StudentExam> exams) async {
    FocusScope.of(context).unfocus();

    if (_urnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your URN to continue.')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your exam date to continue.')),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final matchedExam = exams.cast<StudentExam?>().firstWhere(
          (exam) => exam?.date == formattedDate,
          orElse: () => null,
        );

    if (matchedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No seating arrangement found for the selected date.'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final seating = await _apiService.fetchSeating(matchedExam.examId);
      if (!mounted) return;

      setState(() {
        _selectedExam = seating;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: FutureBuilder<List<StudentExam>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _StudentStateCard(
                title: 'Unable to load exams',
                subtitle:
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Try Again',
                onPressed: _refresh,
              );
            }

            final exams = snapshot.data ?? const <StudentExam>[];

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF4560BD),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Text(
                            'Student Exam Portal',
                            style: TextStyle(
                              color: Color(0xFF111B3A),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find My Seat',
                          style: TextStyle(
                            color: Color(0xFF111B3A),
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter your URN and select your exam date to view your seating arrangement.',
                          style: TextStyle(
                            color: Color(0xFF657794),
                            fontSize: 16,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'UNIVERSITY REGISTRATION NUMBER (URN)',
                          style: TextStyle(
                            color: Color(0xFF253754),
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LookupField(
                          controller: _urnController,
                          icon: Icons.badge_outlined,
                          hintText: 'e.g. 1234567',
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'EXAM DATE',
                          style: TextStyle(
                            color: Color(0xFF253754),
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _DateLookupField(
                          text: _selectedDate == null
                              ? 'mm/dd/yyyy'
                              : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                _isSearching ? null : () => _findSeat(exams),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4560BD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                              shadowColor: const Color(0x3D4560BD),
                            ),
                            icon: _isSearching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.search_rounded, size: 30),
                            label: const Text(
                              'Find My Seat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_selectedExam != null)
                          _StudentResultCard(
                            exam: _selectedExam!,
                            onScreenshot: () => _showActionMessage(
                              'Screenshot feature will be available on device builds.',
                            ),
                            onSaveDate: () => _showActionMessage(
                              'Exam date saved to your schedule.',
                            ),
                          )
                        else if (exams.isEmpty)
                          _StudentStateCard(
                            title: 'No exams assigned',
                            subtitle:
                                'Your seating information will appear here automatically.',
                            actionLabel: 'Refresh',
                            onPressed: _refresh,
                          ),
                        const SizedBox(height: 18),
                        const _SupportCard(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _StudentBottomNav(),
    );
  }
}

class _LookupField extends StatelessWidget {
  const _LookupField({
    required this.controller,
    required this.icon,
    required this.hintText,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF9AA7BD)),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF95A4BD),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6E0F1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6E0F1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4560BD), width: 1.4),
        ),
      ),
    );
  }
}

class _DateLookupField extends StatelessWidget {
  const _DateLookupField({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = text == 'mm/dd/yyyy';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6E0F1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF9AA7BD)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isPlaceholder
                      ? const Color(0xFF95A4BD)
                      : const Color(0xFF111B3A),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF111B3A)),
          ],
        ),
      ),
    );
  }
}

class _StudentResultCard extends StatelessWidget {
  const _StudentResultCard({
    required this.exam,
    required this.onScreenshot,
    required this.onSaveDate,
  });

  final StudentExam exam;
  final VoidCallback onScreenshot;
  final VoidCallback onSaveDate;

  @override
  Widget build(BuildContext context) {
    final examDate = DateTime.parse(exam.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E0F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0812284A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF8E4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: Color(0xFF0A8B42),
                            fontSize: 12,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        exam.subject,
                        style: const TextStyle(
                          color: Color(0xFF111B3A),
                          fontSize: 20,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM d,\nyyyy').format(examDate),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF97A5BE),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      exam.time,
                      style: const TextStyle(
                        color: Color(0xFF97A5BE),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F6FC),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SeatSummaryTile(
                    label: 'EXAM ROOM',
                    value: exam.room,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SeatSummaryTile(
                    label: 'SEAT NUMBER',
                    value: exam.seat,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onScreenshot,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4560BD),
                      side: const BorderSide(color: Color(0xFFD1DBEE)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.screenshot_outlined),
                    label: const Text(
                      'Screenshot',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSaveDate,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4560BD),
                      side: const BorderSide(color: Color(0xFFD1DBEE)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.event_outlined),
                    label: const Text(
                      'Save Date',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatSummaryTile extends StatelessWidget {
  const _SeatSummaryTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6E7F99),
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF4560BD),
              fontSize: highlight ? 28 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EBFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC8D3EE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF4560BD),
            child: Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need assistance?',
                  style: TextStyle(
                    color: Color(0xFF4560BD),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Visit the Exam Support Desk in the Main Lobby if you cannot find your details.',
                  style: TextStyle(
                    color: Color(0xFF5A6FA0),
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentStateCard extends StatelessWidget {
  const _StudentStateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E0F0)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111B3A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF697B97),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4560BD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF4560BD),
      unselectedItemColor: const Color(0xFF9AA7BD),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded, size: 30),
          label: 'LOCATOR',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded, size: 30),
          label: 'SCHEDULE',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined, size: 30),
          label: 'PROFILE',
        ),
      ],
      onTap: (index) {
        if (index == 0) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This section is not available in the current phase.'),
          ),
        );
      },
    );
  }
}
