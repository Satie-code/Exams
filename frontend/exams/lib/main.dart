import 'dart:convert';

import 'package:exams_frontend/screens/admin_dashboard_screen.dart';
import 'package:exams_frontend/screens/faculty_duties_screen.dart';
import 'package:exams_frontend/screens/find_my_seat_screen.dart';
import 'package:exams_frontend/screens/login_screen.dart';
import 'package:exams_frontend/services/auth_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExamsApp());
}

class ExamsApp extends StatelessWidget {
  const ExamsApp({
    super.key,
    this.accessToken = _accessTokenFromEnvironment,
    this.apiBaseUrl = _apiBaseUrlFromEnvironment,
    this.userRole = _userRoleFromEnvironment,
  });

  static const String _accessTokenFromEnvironment = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: '',
  );
  static const String _apiBaseUrlFromEnvironment = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _userRoleFromEnvironment = String.fromEnvironment(
    'USER_ROLE',
    defaultValue: '',
  );

  final String accessToken;
  final String apiBaseUrl;
  final String userRole;

  String _resolvedApiBaseUrl() {
    final configuredBaseUrl = apiBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXAMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4560BD),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0E2F66),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(
              color: Color(0xFFD7E6FF),
            ),
          ),
        ),
      ),
      home: _AuthGate(
        initialAccessToken: accessToken,
        initialUserRole: userRole,
        apiBaseUrl: _resolvedApiBaseUrl(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.initialAccessToken,
    required this.initialUserRole,
    required this.apiBaseUrl,
  });

  final String initialAccessToken;
  final String initialUserRole;
  final String apiBaseUrl;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _accessToken;
  String? _userRole;
  bool _isLoading = true;
  late final AuthApiService _authApi;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiService(baseUrl: widget.apiBaseUrl);
    _initSession();
  }

  Future<void> _initSession() async {
    final envToken = widget.initialAccessToken.trim();
    if (envToken.isNotEmpty) {
      if (mounted) {
        setState(() {
          _accessToken = envToken;
          _userRole = _resolvedRole(
            explicitRole: widget.initialUserRole,
            accessToken: envToken,
          );
          _isLoading = false;
        });
      }
      return;
    }

    final session = await _authApi.loadSession();
    if (mounted) {
      setState(() {
        if (session != null) {
          _accessToken = session.accessToken;
          _userRole = session.role.trim().toUpperCase();
        } else {
          _accessToken = '';
          _userRole = '';
        }
        _isLoading = false;
      });
    }
  }

  String _resolvedRole({
    required String explicitRole,
    required String accessToken,
  }) {
    final normalizedRole = explicitRole.trim().toUpperCase();
    if (normalizedRole.isNotEmpty) {
      return normalizedRole;
    }

    if (accessToken.isEmpty) {
      return '';
    }

    try {
      final segments = accessToken.split('.');
      if (segments.length < 2) {
        return '';
      }

      final normalizedPayload = base64Url.normalize(segments[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalizedPayload)),
      ) as Map<String, dynamic>;

      return (payload['role'] as String? ?? '').trim().toUpperCase();
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleLogin(AuthSession session) async {
    await _authApi.saveSession(session);
    if (mounted) {
      setState(() {
        _accessToken = session.accessToken;
        _userRole = session.role.trim().toUpperCase();
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authApi.clearSession();
    if (mounted) {
      setState(() {
        _accessToken = '';
        _userRole = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_accessToken?.isEmpty ?? true) {
      return LoginScreen(
        apiBaseUrl: widget.apiBaseUrl,
        onLogin: _handleLogin,
      );
    }

    if (_userRole?.isEmpty ?? true) {
      return LoginScreen(
        apiBaseUrl: widget.apiBaseUrl,
        onLogin: _handleLogin,
      );
    }

    if (_userRole == 'FACULTY') {
      return FacultyDutiesScreen(
        accessToken: _accessToken ?? '',
        apiBaseUrl: widget.apiBaseUrl,
      );
    }

    if (_userRole == 'STUDENT') {
      return FindMySeatScreen(
        accessToken: _accessToken ?? '',
        apiBaseUrl: widget.apiBaseUrl,
      );
    }

    if (_userRole == 'ADMIN') {
      return AdminDashboardScreen(
        accessToken: _accessToken ?? '',
        apiBaseUrl: widget.apiBaseUrl,
      );
    }

    return _UnsupportedRoleScreen(
      role: (_userRole?.isEmpty ?? true) ? 'UNKNOWN' : _userRole!,
    );
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen({
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXAMS'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No mobile screen is configured for role: $role',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF12315F),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
