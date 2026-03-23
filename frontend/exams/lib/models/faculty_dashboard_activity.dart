import 'package:exams_frontend/models/faculty_activity.dart';
import 'package:exams_frontend/models/washroom_log.dart';

class FacultyDashboardActivity {
  const FacultyDashboardActivity({
    required this.registeredCount,
    required this.maxCapacity,
    required this.pendingSosCount,
    required this.washroomLogs,
    required this.activities,
  });

  final int registeredCount;
  final int maxCapacity;
  final int pendingSosCount;
  final List<WashroomLog> washroomLogs;
  final List<FacultyActivity> activities;

  factory FacultyDashboardActivity.fromJson(Map<String, dynamic> json) {
    final logsJson = json['washroom_logs'] as List<dynamic>? ?? const [];
    final activitiesJson = json['activities'] as List<dynamic>? ?? const [];

    return FacultyDashboardActivity(
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 0,
      pendingSosCount: (json['pending_sos_count'] as num?)?.toInt() ?? 0,
      washroomLogs: logsJson
          .map((item) => WashroomLog.fromJson(item as Map<String, dynamic>))
          .toList(),
      activities: activitiesJson
          .map((item) => FacultyActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
