import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DutyCard extends StatelessWidget {
  const DutyCard({
    super.key,
    required this.duty,
    required this.isHistory,
    required this.onOpen,
    required this.onSwap,
  });

  final FacultyDuty duty;
  final bool isHistory;
  final VoidCallback onOpen;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = duty.status.toUpperCase() == 'CONFIRMED';
    final bool isPendingAgreement = !isConfirmed && !isHistory;
    final badgeBackground =
        isConfirmed ? const Color(0xFFDDF8E4) : const Color(0xFFEAEFFD);
    final badgeForeground =
        isConfirmed ? const Color(0xFF1A9A49) : const Color(0xFF3157C8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E1F0), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A12284A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            duty.statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: badgeForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          duty.roleLabel,
                          style: const TextStyle(
                            color: Color(0xFF97A5BE),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      duty.subject,
                      style: const TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    MetaRow(
                      icon: Icons.calendar_today_outlined,
                      text:
                          DateFormat('EEE, MMM d, yyyy').format(duty.examDate),
                    ),
                    const SizedBox(height: 12),
                    MetaRow(
                      icon: Icons.access_time_filled_rounded,
                      text: duty.time,
                    ),
                    const SizedBox(height: 12),
                    MetaRow(
                      icon: Icons.location_on_rounded,
                      text: duty.room,
                    ),
                    if (isPendingAgreement) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD8E1F0)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Swap requested with',
                                    style: TextStyle(
                                      color: Color(0xFF74839A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Faculty coordination desk',
                                    style: TextStyle(
                                      color: Color(0xFF3157C8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.hourglass_empty_rounded,
                              color: Color(0xFF3157C8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHistory)
                  const Text(
                    'Completed',
                    style: TextStyle(
                      color: Color(0xFF8A97AE),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (isPendingAgreement)
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Swap cancellation is not available in the current phase.',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF55657F),
                      side: const BorderSide(color: Color(0xFFD1DAE9)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onSwap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onSwap != null
                          ? const Color(0xFF3157C8)
                          : Colors.white,
                      foregroundColor: onSwap != null
                          ? Colors.white
                          : const Color(0xFF55657F),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: onSwap != null
                              ? const Color(0xFF3157C8)
                              : const Color(0xFFD1DAE9),
                        ),
                      ),
                    ),
                    icon: Icon(
                      onSwap != null
                          ? Icons.swap_horiz_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 18,
                    ),
                    label: Text(
                      onSwap != null ? 'Request Swap' : 'Pending Approval',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF4B5B75)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF34445E),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class StateCard extends StatelessWidget {
  const StateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111B3A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF74839A),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onPressed();
                      },
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
