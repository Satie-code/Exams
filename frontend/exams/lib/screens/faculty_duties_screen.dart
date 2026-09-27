import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/screens/faculty_dashboard_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:exams_frontend/widgets/duties/duty_bottom_nav.dart';
import 'package:exams_frontend/widgets/duties/duty_card.dart';
import 'package:exams_frontend/widgets/duties/duty_swap_sheet.dart';
import 'package:exams_frontend/widgets/duties/duty_top_tabs.dart';
import 'package:flutter/material.dart';

class FacultyDutiesScreen extends StatefulWidget {
  const FacultyDutiesScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
    this.api,
  });

  final String accessToken;
  final String apiBaseUrl;
  final FacultyApi? api;

  @override
  State<FacultyDutiesScreen> createState() => _FacultyDutiesScreenState();
}

class _FacultyDutiesScreenState extends State<FacultyDutiesScreen> {
  late final FacultyApi _api;
  late Future<List<FacultyDuty>> _dutiesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _api = widget.api ??
        FacultyApiService(
          baseUrl: widget.apiBaseUrl,
          accessToken: widget.accessToken,
        );
    _dutiesFuture = _loadDuties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<FacultyDuty>> _loadDuties() {
    if (widget.accessToken.isEmpty) {
      return Future<List<FacultyDuty>>.error(
        Exception('Missing access token. Please sign in again.'),
      );
    }

    return _api.fetchDuties();
  }

  Future<void> _refresh() async {
    setState(() {
      _dutiesFuture = _loadDuties();
    });

    await _dutiesFuture;
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Duties',
                style: TextStyle(
                  color: Color(0xFF111B3A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...['ALL', 'CONFIRMED', 'PENDING_SWAP'].map(
                (filter) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    filter == 'ALL'
                        ? 'All duties'
                        : filter == 'CONFIRMED'
                            ? 'Confirmed only'
                            : 'Pending agreement only',
                    style: TextStyle(
                      color: _statusFilter == filter
                          ? const Color(0xFF3157C8)
                          : const Color(0xFF111B3A),
                      fontWeight: _statusFilter == filter
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _statusFilter == filter
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF3157C8))
                      : null,
                  onTap: () {
                    setState(() {
                      _statusFilter = filter;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FacultyDuty> _filteredDuties(List<FacultyDuty> duties) {
    final filteredByTab = duties.where((duty) {
      if (_selectedTabIndex == 0) {
        return !duty.isHistory;
      }

      return duty.isHistory;
    });

    return filteredByTab.where((duty) {
      final matchesSearch = duty.subject.toLowerCase().contains(_searchQuery) ||
          duty.courseCode.toLowerCase().contains(_searchQuery);
      final matchesStatus =
          _statusFilter == 'ALL' || duty.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openSwapSelector(FacultyDuty duty) async {
    try {
      final selectedDuty = await showModalBottomSheet<FacultyDuty>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SwapOptionsSheet(
          duty: duty,
          loader: () => _api.fetchSwapOptions(duty.dutyId),
        ),
      );

      if (selectedDuty == null || !mounted) {
        return;
      }

      await _api.requestSwap(
        requesterDutyId: duty.dutyId,
        targetDutyId: selectedDuty.dutyId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Swap requested for ${duty.courseCode}.'),
        ),
      );

      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _openDashboard(FacultyDuty duty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FacultyDashboardScreen(
          duty: duty,
          api: _api,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
        ),
        title: const Text(
          'Exam Duties',
          style: TextStyle(
            color: Color(0xFF111B3A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
              ),
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 6),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFF1D6C8),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFD8E1F0)),
                bottom: BorderSide(color: Color(0xFFD8E1F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TopTab(
                    title: 'Upcoming Duties',
                    isSelected: _selectedTabIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TopTab(
                    title: 'Duty History',
                    isSelected: _selectedTabIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<FacultyDuty>>(
          future: _dutiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return StateCard(
                title: 'Unable to load duties',
                subtitle:
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Try Again',
                onPressed: _refresh,
              );
            }

            final duties =
                _filteredDuties(snapshot.data ?? const <FacultyDuty>[]);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD8E1F0)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.trim().toLowerCase();
                              });
                            },
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9AA7BD),
                              ),
                              hintText: 'Search by course code...',
                              hintStyle: TextStyle(
                                color: Color(0xFF7E8CA3),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _openFilterSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 68,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD8E1F0)),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF41536F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (duties.isEmpty)
                    StateCard(
                      title: _selectedTabIndex == 0
                          ? 'No upcoming duties'
                          : 'No duty history yet',
                      subtitle:
                          'Your assigned faculty duties will appear here automatically.',
                      actionLabel: 'Refresh',
                      onPressed: _refresh,
                    )
                  else
                    ...duties.map(
                      (duty) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: DutyCard(
                          duty: duty,
                          isHistory: _selectedTabIndex == 1,
                          onOpen: () => _openDashboard(duty),
                          onSwap: duty.canRequestSwap && _selectedTabIndex == 0
                              ? () => _openSwapSelector(duty)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: FacultyBottomNav(
        accessToken: widget.accessToken,
        apiBaseUrl: widget.apiBaseUrl,
      ),
    );
  }
}
