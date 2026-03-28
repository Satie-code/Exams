import 'package:exams_frontend/services/admin_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  final String accessToken;
  final String apiBaseUrl;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminApiService _api;
  IO.Socket? _socket;

  bool _isLoading = true;
  String? _error;

  List<dynamic> _pendingSos = [];
  List<dynamic> _recentActivities = [];
  List<dynamic> _pendingSwaps = [];

  @override
  void initState() {
    super.initState();
    _api = AdminApiService(
      baseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );
    _initDashboard();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    try {
      final data = await _api.fetchDashboard();
      if (mounted) {
        setState(() {
          _pendingSos = List.from(data['pending_sos'] ?? []);
          _recentActivities = List.from(data['recent_activities'] ?? []);
          _pendingSwaps = List.from(data['pending_swaps'] ?? []);
          _isLoading = false;
        });
        _connectSocket();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _connectSocket() {
    final pureUrl = widget.apiBaseUrl.replaceAll('/api', '');

    _socket = IO.io(
      pureUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': widget.accessToken})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('Admin Socket Connected');
    });

    _socket?.on('NEW_SOS', (data) {
      if (mounted) {
        setState(() {
          _pendingSos.insert(0, data);
        });
        _showToast('CRITICAL: New SOS Request in Room ${data['room']}');
      }
    });

    _socket?.on('ACTIVITY_LOGGED', (data) {
      if (mounted) {
        setState(() {
          _recentActivities.insert(0, data);
        });
      }
    });

    _socket?.on('SWAP_REQUESTED', (data) {
      if (mounted) {
        setState(() {
          _pendingSwaps.insert(0, data);
        });
        _showToast('Duty Swap Requested by ${data['requesterFaculty']['name']}');
      }
    });

    _socket?.onDisconnect((_) => debugPrint('Admin Socket Disconnected'));
    _socket?.connect();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5A5A),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _resolveSos(int requestId) async {
    try {
      await _api.resolveSOS(requestId);
      if (!mounted) return;
      setState(() {
        _pendingSos.removeWhere((item) => item['id'] == requestId || item['request_id'] == requestId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS resolved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processSwap(int swapId, bool approved) async {
    try {
      await _api.approveDutySwap(swapRequestId: swapId, approved: approved);
      if (!mounted) return;
      setState(() {
        _pendingSwaps.removeWhere((item) => item['id'] == swapId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Swap Approved' : 'Swap Rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        title: const Text(
          'Command Center',
          style: TextStyle(
            color: Color(0xFF111B3A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, size: 28),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: const Color(0xFFD8E1F0), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load: $_error'))
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_pendingSos.isNotEmpty) ...[
          const _SectionHeader('Active Emergencies (SOS)'),
          const SizedBox(height: 12),
          ..._pendingSos.map((sos) => _buildSosCard(sos)),
          const SizedBox(height: 24),
        ],
        if (_pendingSwaps.isNotEmpty) ...[
          const _SectionHeader('Pending Duty Swaps'),
          const SizedBox(height: 12),
          ..._pendingSwaps.map((swap) => _buildSwapCard(swap)),
          const SizedBox(height: 24),
        ],
        const _SectionHeader('Live Acitivty Feed'),
        const SizedBox(height: 12),
        ..._recentActivities.take(15).map((act) => _buildActivityCard(act)),
      ],
    );
  }

  Widget _buildSosCard(dynamic sos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        border: Border.all(color: const Color(0xFFFFD5D5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5A5A)),
              const SizedBox(width: 8),
              Text(
                'Room ${sos['duty']?['room'] ?? sos['room'] ?? "Unknown"}',
                style: const TextStyle(
                  color: Color(0xFF8B1A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(sos['createdAt'] ?? sos['created_at'] ?? ''),
                style: const TextStyle(color: Color(0xFFB05353)),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Message: ${sos['message']}',
            style: const TextStyle(
              color: Color(0xFF4A1515),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Faculty: ${sos['faculty']?['name'] ?? sos['faculty_name'] ?? 'Unknown'}',
            style: const TextStyle(color: Color(0xFF8B1A1A)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A5A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _resolveSos(sos['id'] ?? sos['request_id']),
              child: const Text('Mark Resolved'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwapCard(dynamic swap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E1F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Color(0xFF3157C8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${swap['requestedByFaculty']?['name'] ?? 'Faculty'} requests swap in ${swap['targetDuty']?['room'] ?? 'a room'}',
                  style: const TextStyle(
                    color: Color(0xFF111B3A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5A5A),
                    side: const BorderSide(color: Color(0xFFFFD5D5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _processSwap(swap['id'], false),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3157C8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _processSwap(swap['id'], true),
                  child: const Text('Approve'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E1F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF3157C8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['message'] ?? 'Action performed',
                  style: const TextStyle(
                    color: Color(0xFF111B3A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      act['faculty']?['name'] ?? 'Unknown Faculty',
                      style: const TextStyle(color: Color(0xFF75859C), fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(act['createdAt'] ?? act['created_at'] ?? ''),
                      style: const TextStyle(color: Color(0xFF75859C), fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4B5B75),
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
