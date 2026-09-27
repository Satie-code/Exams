import 'dart:async';

import 'package:exams_frontend/models/faculty_dashboard_activity.dart';
import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/models/washroom_log.dart';
import 'package:exams_frontend/screens/post_exam_report_screen.dart';
import 'package:exams_frontend/screens/qr_scanner_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:exams_frontend/widgets/faculty/faculty_action_tiles.dart';
import 'package:exams_frontend/widgets/faculty/faculty_activity_panel.dart';
import 'package:exams_frontend/widgets/faculty/faculty_bottom_nav.dart';
import 'package:exams_frontend/widgets/faculty/faculty_dashboard_header.dart';
import 'package:exams_frontend/widgets/faculty/faculty_sos_sheet.dart';
import 'package:exams_frontend/widgets/faculty/faculty_washroom_card.dart';
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
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111B3A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4560BD),
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
      ),
    );
  }

  Future<void> _showSupplySheet() async {
    final itemController = TextEditingController();
    final quantityController = TextEditingController();
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
              SOSOptionTile(
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
              SOSOptionTile(
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
              SOSOptionTile(
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

  ({DateTime start, DateTime end})? _range() {
    try {
      final pieces = widget.duty.time.split('-').map((e) => e.trim()).toList();
      final day = DateFormat('yyyy-MM-dd').format(widget.duty.examDate);
      final parser = DateFormat('yyyy-MM-dd hh:mm a');
      final start = parser.parse('$day ${pieces.first}');
      final end = pieces.length > 1
          ? parser.parse('$day ${pieces.last}')
          : start.add(const Duration(hours: 3));
      return (start: start, end: end);
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
        heroTag: 'dashboard_center_scan_fab',
        onPressed: () => _openQRScanner(
          title: 'Scan Exam Bundle',
          subtitle: 'Point the camera at the bundle manifest QR code.',
          onSubmit: (value) => widget.api.scanBundle(
            dutyId: widget.duty.dutyId,
            bundleId: value,
          ),
          successMessage: 'Bundle scanned successfully.',
        ),
        backgroundColor: const Color(0xFF4560BD),
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      bottomNavigationBar: const DashboardBottomNav(),
      body: SafeArea(
        child: FutureBuilder<FacultyDashboardActivity>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final activities = snapshot.data?.activities ?? const [];
            final logs = snapshot.data?.washroomLogs ?? const <WashroomLog>[];
            final registeredCount = snapshot.data?.registeredCount ?? 0;
            final maxCapacity = snapshot.data?.maxCapacity ?? 0;
            final pendingSosCount = snapshot.data?.pendingSosCount ?? 0;

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                    children: [
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _nowNotifier,
                        builder: (context, now, child) {
                          final countdown = _countdown(now);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardTopBar(
                                title:
                                    '${widget.duty.courseCode} | ${widget.duty.room}',
                                subtitle: _sessionStatus(now),
                              ),
                              const SizedBox(height: 22),
                              DashboardHeader(
                                  duty: widget.duty, countdown: countdown),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const SectionHeading(
                        icon: Icons.qr_code_2_rounded,
                        title: 'QUICK SCANS',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ActionTile(
                              icon: Icons.inventory_2_rounded,
                              title: 'Scan Materials',
                              onTap: () => _openQRScanner(
                                title: 'Scan Exam Bundle',
                                subtitle:
                                    'Point the camera at the bundle manifest QR code.',
                                onSubmit: (value) => widget.api.scanBundle(
                                  dutyId: widget.duty.dutyId,
                                  bundleId: value,
                                ),
                                successMessage:
                                    'Bundle scanned successfully.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ActionTile(
                              icon: Icons.person_search_rounded,
                              title: 'Scan Students',
                              onTap: () => _openQRScanner(
                                title: 'Scan Student ID',
                                subtitle:
                                    'Verify identity and mark attendance via student ID.',
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
                      const SectionHeading(
                        icon: Icons.inventory_outlined,
                        title: 'LOGISTICS & SUPPLIES',
                      ),
                      const SizedBox(height: 18),
                      WideActionTile(
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
                              WideActionTile(
                                icon: Icons.assignment_rounded,
                                title: 'Submit Post-Exam Report',
                                subtitle: 'Reconcile answer sheets & incidents',
                                badgeText: 'Pending',
                                badgeColor: const Color(0xFF35C759),
                                iconBackground: const Color(0xFFE4F9ED),
                                iconColor: const Color(0xFF26B757),
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
                      SectionHeaderRow(
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
                        const EmptyBody(
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
                                  child: WashroomBreakCard(
                                    studentId: log.studentId,
                                    subtitle: exceeded
                                        ? 'Overtime detected!'
                                        : 'Started ${_durationText(Duration(seconds: seconds)).substring(3)} ago',
                                    timerText: '${exceeded ? '-' : ''}$mm:$ss',
                                    timerLabel:
                                        exceeded ? 'EXCEEDED' : 'REMAINING',
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
                      const SectionHeading(
                        icon: Icons.history_rounded,
                        title: 'RECENT ACTIVITY',
                      ),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _nowNotifier,
                        builder: (context, now, child) {
                          return ActivityPanel(
                            activities: activities,
                            ago: (time) => _ago(time, now),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 110,
                  child: FloatingActionButton(
                    heroTag: 'dashboard_emergency_sos_fab',
                    onPressed: _openSOSSheet,
                    backgroundColor: const Color(0xFFE92822),
                    elevation: 6,
                    child: const Icon(
                      Icons.emergency_rounded,
                      color: Colors.white,
                      size: 28,
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
