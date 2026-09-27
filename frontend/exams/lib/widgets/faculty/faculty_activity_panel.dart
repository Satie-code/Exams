import 'package:exams_frontend/models/faculty_activity.dart';
import 'package:exams_frontend/widgets/faculty/faculty_dashboard_header.dart';
import 'package:flutter/material.dart';

class ActivityPanel extends StatelessWidget {
  const ActivityPanel({
    super.key,
    required this.activities,
    required this.ago,
  });

  final List<FacultyActivity> activities;
  final String Function(DateTime time) ago;

  @override
  Widget build(BuildContext context) {
    final visibleActivities = activities.take(3).toList();
    if (visibleActivities.isEmpty) {
      return const EmptyBody(
        text: 'Recent actions will appear here automatically.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E1F1)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visibleActivities.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEEF2F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8A99B4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      visibleActivities[i].message,
                      style: const TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ago(visibleActivities[i].createdAt),
                    style: const TextStyle(
                      color: Color(0xFF8E9CB4),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
