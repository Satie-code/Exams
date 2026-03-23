class FacultyDuty {
  const FacultyDuty({
    required this.dutyId,
    required this.examId,
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.role,
    required this.status,
  });

  final int dutyId;
  final int examId;
  final String subject;
  final String date;
  final String time;
  final String room;
  final String role;
  final String status;

  bool get canRequestSwap => status.toUpperCase() == 'CONFIRMED';

  String get statusLabel {
    final normalized = status.toUpperCase();
    if (normalized == 'PENDING_SWAP') {
      return 'Pending Agreement';
    }

    return 'Confirmed';
  }

  String get roleLabel {
    final normalized = role.toUpperCase();
    if (normalized == 'LEAD') {
      return 'Lead Invigilator';
    }

    return 'Invigilator';
  }

  String get courseCode => subject.split(' ').first;

  DateTime get examDate => DateTime.parse(date);

  DateTime get scheduleStart => _parseTimeBoundary(isEnd: false) ?? examDate;

  DateTime get scheduleEnd =>
      _parseTimeBoundary(isEnd: true) ??
      examDate.add(const Duration(hours: 23, minutes: 59));

  bool get isHistory => scheduleEnd.isBefore(DateTime.now());

  DateTime? _parseTimeBoundary({required bool isEnd}) {
    try {
      final segments = time.split('-').map((item) => item.trim()).toList();
      final selected = isEnd && segments.length > 1 ? segments.last : segments.first;
      final parser = DateTime.parse(date);
      final day = '${parser.year.toString().padLeft(4, '0')}-${parser.month.toString().padLeft(2, '0')}-${parser.day.toString().padLeft(2, '0')}';

      final format = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)$', caseSensitive: false);
      final match = format.firstMatch(selected.toUpperCase());

      if (match == null) {
        return null;
      }

      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final meridiem = match.group(3)!.toUpperCase();

      if (meridiem == 'PM' && hour != 12) {
        hour += 12;
      }

      if (meridiem == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime.parse('$day ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00');
    } catch (_) {
      return null;
    }
  }

  factory FacultyDuty.fromJson(Map<String, dynamic> json) {
    return FacultyDuty(
      dutyId: (json['duty_id'] as num).toInt(),
      examId: (json['exam_id'] as num).toInt(),
      subject: json['subject'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      room: json['room'] as String,
      role: json['role'] as String,
      status: (json['status'] as String?) ?? 'CONFIRMED',
    );
  }
}
