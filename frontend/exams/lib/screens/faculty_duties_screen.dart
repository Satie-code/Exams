import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/screens/faculty_dashboard_screen.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:exams_frontend/screens/faculty_swaps_screen.dart';
import 'package:exams_frontend/screens/faculty_colleagues_screen.dart';
import 'package:exams_frontend/screens/faculty_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                    style: const TextStyle(
                      color: Color(0xFF4A5A78),
                      fontWeight: FontWeight.w600,
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
        builder: (context) => _SwapOptionsSheet(
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
                  child: _TopTab(
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
                  child: _TopTab(
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
              return _StateCard(
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
                    _StateCard(
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
                        child: _DutyCard(
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
      bottomNavigationBar: _FacultyBottomNav(
        accessToken: widget.accessToken,
        apiBaseUrl: widget.apiBaseUrl,
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF3157C8) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF3157C8)
                  : const Color(0xFF75859C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({
    required this.duty,
    required this.isHistory,
    required this.onOpen,
    required this.onSwap,
  });

  final FacultyDuty duty;
  final bool isHistory;
  final VoidCallback onOpen;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = duty.status.toUpperCase() == 'CONFIRMED';
    final bool isPendingAgreement = !isConfirmed && !isHistory;
    final badgeBackground =
        isConfirmed ? const Color(0xFFDDF8E4) : const Color(0xFFEAEFFD);
    final badgeForeground =
        isConfirmed ? const Color(0xFF1A9A49) : const Color(0xFF3157C8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E1F0), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A12284A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            duty.statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: badgeForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          duty.roleLabel,
                          style: const TextStyle(
                            color: Color(0xFF97A5BE),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      duty.subject,
                      style: const TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      text:
                          DateFormat('EEE, MMM d, yyyy').format(duty.examDate),
                    ),
                    const SizedBox(height: 12),
                    _MetaRow(
                      icon: Icons.access_time_filled_rounded,
                      text: duty.time,
                    ),
                    const SizedBox(height: 12),
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      text: duty.room,
                    ),
                    if (isPendingAgreement) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD1DAE9),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF7D8DA7),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Swap requested with',
                                    style: TextStyle(
                                      color: Color(0xFF74839A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Faculty coordination desk',
                                    style: TextStyle(
                                      color: Color(0xFF3157C8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.hourglass_empty_rounded,
                              color: Color(0xFF3157C8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHistory)
                  const Text(
                    'Completed',
                    style: TextStyle(
                      color: Color(0xFF8A97AE),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (isPendingAgreement)
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Swap cancellation is not available in the current phase.',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF55657F),
                      side: const BorderSide(color: Color(0xFFD1DAE9)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onSwap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onSwap != null
                          ? const Color(0xFF3157C8)
                          : Colors.white,
                      foregroundColor: onSwap != null
                          ? Colors.white
                          : const Color(0xFF55657F),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: onSwap != null
                              ? const Color(0xFF3157C8)
                              : const Color(0xFFD1DAE9),
                        ),
                      ),
                    ),
                    icon: Icon(
                      onSwap != null
                          ? Icons.swap_horiz_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 18,
                    ),
                    label: Text(
                      onSwap != null ? 'Request Swap' : 'Pending Approval',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF4B5B75)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF34445E),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwapOptionsSheet extends StatelessWidget {
  const _SwapOptionsSheet({
    required this.duty,
    required this.loader,
  });

  final FacultyDuty duty;
  final Future<List<FacultyDuty>> Function() loader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Swap Duty',
                  style: TextStyle(
                    color: Color(0xFF111B3A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose another confirmed duty for ${duty.courseCode}.',
                  style: const TextStyle(
                    color: Color(0xFF74839A),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FacultyDuty>>(
              future: loader(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF74839A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final options = snapshot.data ?? const <FacultyDuty>[];

                if (options.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No confirmed duties are currently available for swap.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF74839A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];

                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).pop(option),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        title: Text(
                          option.subject,
                          style: const TextStyle(
                            color: Color(0xFF111B3A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${DateFormat('EEE, MMM d, yyyy').format(option.examDate)}\n${option.time}  |  ${option.room}',
                            style: const TextStyle(
                              color: Color(0xFF74839A),
                              height: 1.5,
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF3157C8),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
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
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111B3A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF74839A),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onPressed();
                      },
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FacultyBottomNav extends StatelessWidget {
  const _FacultyBottomNav({
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
