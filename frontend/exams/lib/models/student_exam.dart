class StudentExam {
  const StudentExam({
    required this.examId,
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.seat,
  });

  final int examId;
  final String subject;
  final String date;
  final String time;
  final String room;
  final String seat;

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    return StudentExam(
      examId: (json['exam_id'] as num).toInt(),
      subject: json['subject'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      room: json['room'] as String,
      seat: json['seat'] as String,
    );
  }
}
