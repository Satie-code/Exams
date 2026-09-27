import 'package:flutter/material.dart';

class WashroomBreakCard extends StatelessWidget {
  const WashroomBreakCard({
    super.key,
    required this.studentId,
    required this.subtitle,
    required this.timerText,
    required this.timerLabel,
    required this.color,
    required this.alert,
    required this.onStop,
  });

  final String studentId;
  final String subtitle;
  final String timerText;
  final String timerLabel;
  final Color color;
  final bool alert;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFF4F4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alert ? const Color(0xFFFFB8B5) : const Color(0xFFD7E1F1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: alert ? const Color(0xFFFFE3E2) : const Color(0xFFDDF7E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              alert
                  ? Icons.warning_amber_rounded
                  : Icons.directions_run_rounded,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ID: $studentId',
                  style: const TextStyle(
                    color: Color(0xFF111B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                timerText,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timerLabel,
                style: TextStyle(
                  color: color.withValues(alpha: 0.82),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onStop,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 56,
              height: 70,
              decoration: BoxDecoration(
                color:
                    alert ? const Color(0xFFFF453A) : const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.close_rounded,
                color: alert ? Colors.white : const Color(0xFF596A86),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
