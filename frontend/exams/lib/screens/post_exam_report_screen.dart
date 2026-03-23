import 'package:exams_frontend/models/faculty_duty.dart';
import 'package:exams_frontend/services/faculty_api_service.dart';
import 'package:flutter/material.dart';

class PostExamReportScreen extends StatefulWidget {
  const PostExamReportScreen({
    super.key,
    required this.duty,
    required this.api,
    required this.registeredCount,
    required this.maxCapacity,
  });

  final FacultyDuty duty;
  final FacultyApi api;
  final int registeredCount;
  final int maxCapacity;

  @override
  State<PostExamReportScreen> createState() => _PostExamReportScreenState();
}

class _PostExamReportScreenState extends State<PostExamReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _presentController = TextEditingController(text: '0');
  final _sheetController = TextEditingController(text: '0');
  final _incidentController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _noIncidents = true;
  bool _declarationAccepted = false;
  bool _showDeclarationError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _presentController.dispose();
    _sheetController.dispose();
    _incidentController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final parsedValue = int.tryParse((value ?? '').trim());
    if (parsedValue == null || parsedValue < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _showDeclarationError = !_declarationAccepted;
    });

    if (!isValid || !_declarationAccepted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.api.submitReport(
        dutyId: widget.duty.dutyId,
        totalStudentsPresent: int.parse(_presentController.text.trim()),
        totalAnswerSheetsCollected: int.parse(_sheetController.text.trim()),
        noIncidents: _noIncidents,
        incidentDetails: _incidentController.text.trim(),
        remarks: _remarksController.text.trim(),
        declarationAccepted: _declarationAccepted,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post-exam report submitted successfully.'),
          backgroundColor: Color(0xFF4360BF),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFE55656),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EDF8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF3455BE),
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Post-Exam Report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                  children: [
                    _ReportHeroCard(duty: widget.duty),
                    const SizedBox(height: 22),
                    const Text(
                      'Attendance & Collection',
                      style: TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricCard(
                            label: 'TOTAL REGISTERED',
                            value: widget.registeredCount.toString(),
                            highlight: true,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryMetricCard(
                            label: 'MAX CAPACITY',
                            value: widget.maxCapacity.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Total Students Present',
                      style: TextStyle(
                        color: Color(0xFF233555),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NumberInputCard(
                      controller: _presentController,
                      icon: Icons.groups_rounded,
                      validator: _validateNumber,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Total Answer Sheets Collected',
                      style: TextStyle(
                        color: Color(0xFF233555),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NumberInputCard(
                      controller: _sheetController,
                      icon: Icons.description_rounded,
                      validator: _validateNumber,
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFDCE3F1), height: 1),
                    const SizedBox(height: 24),
                    const Text(
                      'Irregularities & Incidents',
                      style: TextStyle(
                        color: Color(0xFF111B3A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'No incidents to report',
                              style: TextStyle(
                                color: Color(0xFF334765),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _noIncidents,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF4360BF),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFC6D0E6),
                            onChanged: (value) {
                              setState(() {
                                _noIncidents = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Incident Details (Optional)',
                      style: TextStyle(
                        color: Color(0xFF233555),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TextAreaCard(
                      controller: _incidentController,
                      hint:
                          'Describe any malpractice, medical issues, or technical glitches...',
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        color: Color(0xFF233555),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TextAreaCard(
                      controller: _remarksController,
                      hint:
                          'Add any final collection notes or invigilation remarks...',
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _showDeclarationError
                              ? const Color(0xFFE55656)
                              : const Color(0xFFCBD7EE),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _declarationAccepted,
                            activeColor: const Color(0xFF4360BF),
                            onChanged: (value) {
                              setState(() {
                                _declarationAccepted = value ?? false;
                                _showDeclarationError = false;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'I hereby certify that the counts and reports provided above are accurate and verified by the invigilation team.',
                                style: TextStyle(
                                  color: Color(0xFF324562),
                                  fontSize: 15,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showDeclarationError) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Declaration checkbox is required.',
                        style: TextStyle(
                          color: Color(0xFFE55656),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4360BF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.assignment_turned_in_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Submit & Generate Report',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({
    required this.duty,
  });

  final FacultyDuty duty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A13274B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              gradient: LinearGradient(
                colors: [Color(0xFF2E447E), Color(0xFF7086B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'SESSION ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      duty.courseCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      duty.subject,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              children: [
                _HeroMetaRow(
                  icon: Icons.location_on_rounded,
                  text: duty.room,
                ),
                const SizedBox(height: 14),
                _HeroMetaRow(
                  icon: Icons.access_time_filled_rounded,
                  text: duty.time,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEFB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: const Color(0xFF4360BF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF354867),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6C7B95),
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color:
                  highlight ? const Color(0xFF4360BF) : const Color(0xFF111B3A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInputCard extends StatelessWidget {
  const _NumberInputCard({
    required this.controller,
    required this.icon,
    required this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF97A5BE)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC9D5EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC9D5EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4360BF), width: 1.4),
        ),
      ),
    );
  }
}

class _TextAreaCard extends StatelessWidget {
  const _TextAreaCard({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF6E7D97),
          fontSize: 15,
          height: 1.5,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC9D5EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC9D5EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4360BF), width: 1.4),
        ),
      ),
    );
  }
}
