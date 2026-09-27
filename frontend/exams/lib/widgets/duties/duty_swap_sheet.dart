import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SwapOptionsSheet extends StatelessWidget {
  const SwapOptionsSheet({
    super.key,
    required this.duty,
    required this.loader,
  });

  final FacultyDuty duty;
  final Future<List<FacultyDuty>> Function() loader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Swap Duty',
                  style: TextStyle(
                    color: Color(0xFF111B3A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose another confirmed duty for ${duty.courseCode}.',
                  style: const TextStyle(
                    color: Color(0xFF74839A),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FacultyDuty>>(
              future: loader(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF74839A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final options = snapshot.data ?? const <FacultyDuty>[];

                if (options.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No confirmed duties are currently available for swap.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF74839A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];

                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).pop(option),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        title: Text(
                          option.subject,
                          style: const TextStyle(
                            color: Color(0xFF111B3A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${DateFormat('EEE, MMM d, yyyy').format(option.examDate)}\n${option.time}  |  ${option.room}',
                            style: const TextStyle(
                              color: Color(0xFF74839A),
                              height: 1.5,
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF3157C8),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
