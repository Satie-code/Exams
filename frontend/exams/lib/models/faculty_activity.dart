class FacultyActivity {
  const FacultyActivity({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String type;
  final DateTime createdAt;
  final String message;

  factory FacultyActivity.fromJson(Map<String, dynamic> json) {
    return FacultyActivity(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
