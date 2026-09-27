import 'package:flutter/material.dart';

class SOSOptionTile extends StatelessWidget {
  const SOSOptionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.isUrgent = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: isUrgent ? const Color(0xFFFFF3F2) : const Color(0xFFF6F8FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Icon(
        isUrgent
            ? Icons.warning_amber_rounded
            : Icons.circle_notifications_rounded,
        color: isUrgent ? const Color(0xFFE92822) : const Color(0xFF4560BD),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isUrgent ? const Color(0xFFE92822) : const Color(0xFF111B3A),
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
