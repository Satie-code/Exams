import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFF4560BD),
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111B3A),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6F7F99),
                  fontSize: 14,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.notifications_rounded,
          color: Color(0xFF111B3A),
          size: 28,
        ),
        const SizedBox(width: 14),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF4560BD),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'JS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.duty,
    required this.countdown,
  });

  final FacultyDuty duty;
  final ({String label, String value, String helper}) countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF4A61BC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countdown.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  countdown.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.timer_outlined,
            color: Color(0x85FFFFFF),
            size: 66,
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7A88A1), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6F7F99),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class SectionHeaderRow extends StatelessWidget {
  const SectionHeaderRow({
    super.key,
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7A88A1), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6F7F99),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF4560BD),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyBody extends StatelessWidget {
  const EmptyBody({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7F8CA3),
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
