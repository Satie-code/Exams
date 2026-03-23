class WashroomLog {
  const WashroomLog({
    required this.logId,
    required this.studentId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.status,
    required this.state,
  });

  final int logId;
  final String studentId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String status;
  final String state;

  factory WashroomLog.fromJson(Map<String, dynamic> json) {
    return WashroomLog(
      logId: (json['log_id'] as num).toInt(),
      studentId: json['student_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      status: json['status'] as String,
      state: json['state'] as String,
    );
  }
}
