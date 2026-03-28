import 'dart:async';

import 'package:exams_frontend/models/faculty_activity.dart';
import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/models/washroom_log.dart';
import 'package:exams_frontend/screens/post_exam_report_screen.dart';
import 'package:exams_frontend/screens/qr_scanner_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({
    super.key,
    required this.duty,
    required this.api,
  });

  final FacultyDuty duty;
  final FacultyApi api;

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  static const Color _successColor = Color(0xFF25B468);
  static const Color _errorColor = Color(0xFFE55656);
  static const int _washroomWarningSeconds = 5 * 60;
  static const int _washroomViolationSeconds = 10 * 60;

  late Future<FacultyDashboardActivity> _dashboardFuture;
  Timer? _ticker;
  final ValueNotifier<DateTime> _nowNotifier = ValueNotifier(DateTime.now());

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.api.fetchActivity(dutyId: widget.duty.dutyId);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _nowNotifier.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = widget.api.fetchActivity(dutyId: widget.duty.dutyId);
    });
    await _dashboardFuture;
  }

  void _showFeedback(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runAction(
      Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      _showFeedback(success, backgroundColor: _successColor);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        error.toString().replaceFirst('Exception: ', ''),
        backgroundColor: _errorColor,
      );
    }
  }

  Future<void> _showSingleInputSheet({
    required String title,
    required String label,
    required String actionLabel,
    required Future<void> Function(String value) onSubmit,
  }) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: label,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.isEmpty) return;
                  Navigator.of(context).pop();
                  await onSubmit(value);
                },
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSupplySheet() async {
    final itemController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Supplies',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: itemController,
              decoration: InputDecoration(
                labelText: 'Supply item',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final item = itemController.text.trim();
                  final quantity = int.tryParse(quantityController.text.trim());
                  if (item.isEmpty || quantity == null || quantity <= 0) return;
                  Navigator.of(context).pop();
                  await _runAction(
                    () => widget.api.requestSupplies(
                      dutyId: widget.duty.dutyId,
                      item: item,
                      quantity: quantity,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    ),
                    'Supply request sent.',
                  );
                },
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestSOS(String message, String successMessage) async {
    await _runAction(
      () => widget.api.requestSOS(
        dutyId: widget.duty.dutyId,
        message: message,
      ),
      successMessage,
    );
  }

  Future<void> _openSOSSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOS Requests',
                style: TextStyle(
                  color: Color(0xFF111B3A),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _SOSOptionTile(
                title: 'Answer Sheets',
                onTap: () async {
                  Navigator.of(context).pop();
                  await _requestSOS(
                    'ANSWER_SHEETS',
                    'SOS request sent for answer sheets.',
                  );
                },
              ),
              const SizedBox(height: 10),
              _SOSOptionTile(
                title: 'Stationery',
                onTap: () async {
                  Navigator.of(context).pop();
                  await _requestSOS(
                    'STATIONERY',
                    'SOS request sent for stationery.',
                  );
                },
              ),
              const SizedBox(height: 10),
              _SOSOptionTile(
                title: 'Urgent Help',
                isUrgent: true,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _requestSOS(
                    'URGENT_HELP',
                    'Urgent help request sent.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPostExamReport({
    required int registeredCount,
    required int maxCapacity,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostExamReportScreen(
          duty: widget.duty,
          api: widget.api,
          registeredCount: registeredCount,
          maxCapacity: maxCapacity,
        ),
      ),
    );

    if (result == true && mounted) {
      await _refresh();
    }
  }

  _TimeRange? _range() {
    try {
      final pieces = widget.duty.time.split('-').map((e) => e.trim()).toList();
      final day = DateFormat('yyyy-MM-dd').format(widget.duty.examDate);
      final parser = DateFormat('yyyy-MM-dd hh:mm a');
      final start = parser.parse('$day ${pieces.first}');
      final end = pieces.length > 1
          ? parser.parse('$day ${pieces.last}')
          : start.add(const Duration(hours: 3));
      return _TimeRange(start, end);
    } catch (_) {
      return null;
    }
  }

  String _durationText(Duration duration) {
    final s = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  ({String label, String value, String helper}) _countdown(DateTime now) {
    final range = _range();
    if (range == null) {
      return (label: 'Exam Timer', value: '--:--:--', helper: widget.duty.time);
    }
    if (now.isBefore(range.start)) {
      return (
        label: 'Starts In',
        value: _durationText(range.start.difference(now)),
        helper:
            '${DateFormat('dd MMM yyyy').format(widget.duty.examDate)} - ${widget.duty.time}'
      );
    }
    if (now.isBefore(range.end)) {
      return (
        label: 'Ends In',
        value: _durationText(range.end.difference(now)),
        helper:
            '${DateFormat('dd MMM yyyy').format(widget.duty.examDate)} - ${widget.duty.time}'
      );
    }
    return (
      label: 'Exam Completed',
      value: '00:00:00',
      helper:
          '${DateFormat('dd MMM yyyy').format(widget.duty.examDate)} - ${widget.duty.time}'
    );
  }

  String _ago(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(time);
  }

  String _liveWashroomState(WashroomLog log, DateTime now) {
    if (log.endTime != null) {
      return log.state;
    }

    final durationSeconds =
        now.difference(log.startTime).inSeconds.clamp(0, 24 * 60 * 60);

    if (durationSeconds >= _washroomViolationSeconds) {
      return 'red';
    }

    if (durationSeconds >= _washroomWarningSeconds) {
      return 'yellow';
    }

    return 'green';
  }

  String _sessionStatus(DateTime now) {
    final countdown = _countdown(now);
    if (countdown.label == 'Starts In') {
      return 'EXAM STARTS SOON';
    }
    if (countdown.label == 'Exam Completed') {
      return 'EXAM COMPLETED';
    }
    return 'EXAM IN PROGRESS';
  }

  Future<void> _openQRScanner({
    required String title,
    required String subtitle,
    required Future<void> Function(String value) onSubmit,
    required String successMessage,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => QRScannerScreen(
          title: title,
          subtitle: subtitle,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await _runAction(() => onSubmit(result), successMessage);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQRScanner(
          title: 'Scan Exam Bundle',
          subtitle: 'Point the camera at the bundle manifest QR code.',
          onSubmit: (value) => widget.api.scanBundle(
            dutyId: widget.duty.dutyId,
            bundleId: value,
          ),
          successMessage: 'Bundle verified and logged successfully.',
        ),
        backgroundColor: const Color(0xFF4560BD),
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
      ),
      bottomNavigationBar: const _DashboardBottomNav(),
      body: SafeArea(
        child: FutureBuilder<FacultyDashboardActivity>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final pendingSosCount = snapshot.data?.pendingSosCount ?? 0;
            final registeredCount = snapshot.data?.registeredCount ?? 0;
            final maxCapacity = snapshot.data?.maxCapacity ?? 0;
            final logs = snapshot.data?.washroomLogs ?? const <WashroomLog>[];
            final activities =
                snapshot.data?.activities ?? const <FacultyActivity>[];

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 120),
                    children: [
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _nowNotifier,
                        builder: (context, now, child) {
                          final countdown = _countdown(now);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DashboardTopBar(
                                title: '${widget.duty.courseCode} | ${widget.duty.room}',
                                subtitle: _sessionStatus(now),
                              ),
                              const SizedBox(height: 22),
                              _DashboardHeader(duty: widget.duty, countdown: countdown),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const _SectionHeading(
                        icon: Icons.qr_code_2_rounded,
                        title: 'QUICK SCANS',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.inventory_2_rounded,
                              title: 'Scan Materials',
                              onTap: () => _openQRScanner(
                                title: 'Scan Exam Bundle',
                                subtitle: 'Point the camera at the bundle manifest QR code.',
                                onSubmit: (value) => widget.api.scanBundle(
                                  dutyId: widget.duty.dutyId,
                                  bundleId: value,
                                ),
                                successMessage: 'Bundle verified and logged successfully.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.person_search_rounded,
                              title: 'Scan Students',
                              onTap: () => _openQRScanner(
                                title: 'Scan Student ID',
                                subtitle: 'Verify identity and mark attendance via student ID.',
                                onSubmit: (value) => widget.api.markAttendance(
                                  dutyId: widget.duty.dutyId,
                                  studentIdentifier: value,
                                ),
                                successMessage: 'Student attendance marked.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const _SectionHeading(
                        icon: Icons.inventory_outlined,
                        title: 'LOGISTICS & SUPPLIES',
                      ),
                      const SizedBox(height: 18),
                      _WideActionTile(
                        icon: Icons.shopping_cart_checkout_rounded,
                        title: 'Request Supplies',
                        subtitle: 'Sheets, threads, stationery',
                        badgeText: pendingSosCount > 0
                            ? '$pendingSosCount Pending'
                            : 'Open',
                        badgeColor: const Color(0xFFF7A400),
                        iconBackground: const Color(0xFFFFF0C9),
                        iconColor: const Color(0xFFF09A00),
                        onTap: _showSupplySheet,
                      ),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _nowNotifier,
                        builder: (context, now, child) {
                          final count = _countdown(now);
                          if (count.label != 'Exam Completed') {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        const SizedBox(height: 14),
                        _WideActionTile(
                          icon: Icons.assignment_rounded,
                          title: 'Post-Exam Report',
                          subtitle:
                              'Attendance summary, sheet count, incidents and remarks',
                          iconBackground: const Color(0xFFEAF0FF),
                          iconColor: const Color(0xFF4560BD),
                          onTap: () => _openPostExamReport(
                            registeredCount: registeredCount,
                            maxCapacity: maxCapacity,
                          ),
                        ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionHeaderRow(
                        title: 'WASHROOM BREAKS',
                        icon: Icons.people_alt_outlined,
                        actionLabel: '+ New Break',
                        onTap: () => _showSingleInputSheet(
                          title: 'Start Washroom Timer',
                          label: 'Student ID / register number',
                          actionLabel: 'Start Timer',
                          onSubmit: (value) => _runAction(
                            () => widget.api.startWashroomTimer(
                              dutyId: widget.duty.dutyId,
                              studentId: value,
                            ),
                            'Washroom timer started.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (logs.isEmpty)
                        const _EmptyBody(
                          text: 'No students are currently out of the room.',
                        )
                      else
                        ValueListenableBuilder<DateTime>(
                          valueListenable: _nowNotifier,
                          builder: (context, now, child) {
                            return Column(
                              children: logs.map((log) {
                                final seconds = now
                                    .difference(log.startTime)
                                    .inSeconds
                                    .clamp(0, 86400);
                                final remainingSeconds =
                                    _washroomViolationSeconds - seconds;
                                final liveState = _liveWashroomState(log, now);
                                final exceeded = liveState == 'red';
                                final color = exceeded
                                    ? const Color(0xFFFF3B30)
                                    : const Color(0xFF0BA360);
                                final absoluteSeconds = remainingSeconds.abs();
                                final mm = (absoluteSeconds ~/ 60)
                                    .toString()
                                    .padLeft(2, '0');
                                final ss = (absoluteSeconds % 60)
                                    .toString()
                                    .padLeft(2, '0');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _WashroomBreakCard(
                              studentId: log.studentId,
                              subtitle: exceeded
                                  ? 'Overtime detected!'
                                  : 'Started ${_durationText(Duration(seconds: seconds)).substring(3)} ago',
                              timerText: '${exceeded ? '-' : ''}$mm:$ss',
                              timerLabel: exceeded ? 'EXCEEDED' : 'REMAINING',
                              color: color,
                              alert: exceeded,
                              onStop: () => _runAction(
                                () => widget.api.endWashroomTimer(
                                  dutyId: widget.duty.dutyId,
                                  studentId: log.studentId,
                                ),
                                'Washroom timer ended.',
                              ),
                            ),
                          );
                        }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                      const _SectionHeading(
                        icon: Icons.history_rounded,
                        title: 'RECENT ACTIVITY',
                      ),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _nowNotifier,
                        builder: (context, now, child) {
                          return _ActivityPanel(
                              activities: activities,
                              ago: (time) => _ago(time, now));
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 26,
                  bottom: 110,
                  child: InkWell(
                    onTap: _openSOSSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE92822),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x38E92822),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.school_rounded,
              color: Color(0xFF4560BD), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111B3A),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6F7F99),
                  fontSize: 14,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.notifications_rounded,
            color: Color(0xFF111B3A), size: 28),
        const SizedBox(width: 14),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF4560BD),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'JS',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.duty,
    required this.countdown,
  });

  final FacultyDuty duty;
  final ({String label, String value, String helper}) countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF4A61BC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countdown.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  countdown.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.timer_outlined, color: Color(0x85FFFFFF), size: 66),
        ],
      ),
    );
  }
}

class _TimeRange {
  const _TimeRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7A88A1), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6F7F99),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7A88A1), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6F7F99),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF4560BD),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        height: 172,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD7E1F1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3FC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF4560BD), size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111B3A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideActionTile extends StatelessWidget {
  const _WideActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
    this.iconBackground = const Color(0xFFEAF0FF),
    this.iconColor = const Color(0xFF3157C8),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD7E1F1)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111B3A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7C97),
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF4560BD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA7BD)),
          ],
        ),
      ),
    );
  }
}

class _WashroomBreakCard extends StatelessWidget {
  const _WashroomBreakCard({
    required this.studentId,
    required this.subtitle,
    required this.timerText,
    required this.timerLabel,
    required this.color,
    required this.alert,
    required this.onStop,
  });

  final String studentId;
  final String subtitle;
  final String timerText;
  final String timerLabel;
  final Color color;
  final bool alert;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFF4F4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alert ? const Color(0xFFFFB8B5) : const Color(0xFFD7E1F1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: alert ? const Color(0xFFFFE3E2) : const Color(0xFFDDF7E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              alert
                  ? Icons.warning_amber_rounded
                  : Icons.directions_run_rounded,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ID: $studentId',
                  style: const TextStyle(
                    color: Color(0xFF111B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                timerText,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                timerLabel,
                style: TextStyle(
                  color: color.withValues(alpha: 0.82),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onStop,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 56,
              height: 70,
              decoration: BoxDecoration(
                color:
                    alert ? const Color(0xFFFF453A) : const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.close_rounded,
                color: alert ? Colors.white : const Color(0xFF596A86),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.activities,
    required this.ago,
  });

  final List<FacultyActivity> activities;
  final String Function(DateTime time) ago;

  @override
  Widget build(BuildContext context) {
    final visibleActivities = activities.take(3).toList();
    if (visibleActivities.isEmpty) {
      return const _EmptyBody(
          text: 'Recent actions will appear here automatically.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E1F1)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visibleActivities.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEEF2F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF8A99B4), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      visibleActivities[i].message,
                      style: const TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ago(visibleActivities[i].createdAt),
                    style: const TextStyle(
                      color: Color(0xFF8E9CB4),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SOSOptionTile extends StatelessWidget {
  const _SOSOptionTile({
    required this.title,
    required this.onTap,
    this.isUrgent = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: isUrgent ? const Color(0xFFFFF3F2) : const Color(0xFFF6F8FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Icon(
        isUrgent
            ? Icons.warning_amber_rounded
            : Icons.circle_notifications_rounded,
        color: isUrgent ? const Color(0xFFE92822) : const Color(0xFF4560BD),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isUrgent ? const Color(0xFFE92822) : const Color(0xFF111B3A),
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  @override
  Widget build(BuildContext context) {
    return const BottomAppBar(
      height: 82,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      notchMargin: 8,
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: true),
          _NavItem(icon: Icons.people_alt_outlined, label: 'Roster'),
          SizedBox(width: 54),
          _NavItem(icon: Icons.error_outline_rounded, label: 'Incidents'),
          _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4560BD) : const Color(0xFF98A7BF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 29),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7F8CA3),
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
