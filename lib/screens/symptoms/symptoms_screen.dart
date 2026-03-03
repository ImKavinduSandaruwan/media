import 'package:flutter/material.dart';
import 'package:app/services/tracker_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:intl/intl.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final _trackerService = TrackerService();
  final List<String> _selectedSymptoms = [];
  bool _noSymptoms = false;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _symptoms = [
    {
      'label': 'Unusual bleeding',
      'value': 'unusual_bleeding',
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFEE2E2),
      'serious': true,
    },
    {
      'label': 'Bruising',
      'value': 'bruising',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
      'serious': false,
    },
    {
      'label': 'Dizziness',
      'value': 'dizziness',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
      'serious': false,
    },
    {
      'label': 'Headache',
      'value': 'headache',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
      'serious': false,
    },
    {
      'label': 'Chest pain',
      'value': 'chest_pain',
      'color': const Color(0xFFDC2626),
      'bgColor': const Color(0xFFFEE2E2),
      'serious': true,
    },
    {
      'label': 'Shortness of breath',
      'value': 'shortness_of_breath',
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFEE2E2),
      'serious': true,
    },
    {
      'label': 'Fatigue',
      'value': 'fatigue',
      'color': const Color(0xFFEAB308),
      'bgColor': const Color(0xFFFEF3C7),
      'serious': false,
    },
    {
      'label': 'Nausea',
      'value': 'nausea',
      'color': const Color(0xFFEAB308),
      'bgColor': const Color(0xFFFEF3C7),
      'serious': false,
    },
    {
      'label': 'Blood in urine/stool',
      'value': 'blood_in_urine_stool',
      'color': const Color(0xFFDC2626),
      'bgColor': const Color(0xFFFEE2E2),
      'serious': true,
    },
    {
      'label': 'Swelling',
      'value': 'swelling',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
      'serious': false,
    },
    {
      'label': 'Rapid heartbeat',
      'value': 'rapid_heartbeat',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
      'serious': false,
    },
    {
      'label': 'Weakness',
      'value': 'weakness',
      'color': const Color(0xFFEAB308),
      'bgColor': const Color(0xFFFEF3C7),
      'serious': false,
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _canSave() {
    return !_isLoading && (_noSymptoms || _selectedSymptoms.isNotEmpty);
  }

  bool _hasSeriousSymptoms() {
    return _selectedSymptoms.any((symptomValue) {
      final symptom = _symptoms.firstWhere(
        (s) => s['value'] == symptomValue,
        orElse: () => {'serious': false},
      );
      return symptom['serious'] == true;
    });
  }

  Color _getSymptomColor(String symptomValue) {
    final symptom = _symptoms.firstWhere(
      (s) => s['value'] == symptomValue,
      orElse: () => {'color': const Color(0xFFEF4444)},
    );
    return symptom['color'] as Color;
  }

  Color _getSymptomBgColor(String symptomValue) {
    final symptom = _symptoms.firstWhere(
      (s) => s['value'] == symptomValue,
      orElse: () => {'bgColor': const Color(0xFFFEE2E2)},
    );
    return symptom['bgColor'] as Color;
  }

  String _getSymptomLabel(String symptomValue) {
    final symptom = _symptoms.firstWhere(
      (s) => s['value'] == symptomValue,
      orElse: () => {'label': ''},
    );
    return symptom['label'] as String;
  }

  void _toggleSymptom(String symptomValue) {
    setState(() {
      if (_selectedSymptoms.contains(symptomValue)) {
        _selectedSymptoms.remove(symptomValue);
      } else {
        _selectedSymptoms.add(symptomValue);
        _noSymptoms = false;
      }
    });
  }

  void _selectNoSymptoms() {
    setState(() {
      _noSymptoms = true;
      _selectedSymptoms.clear();
    });
  }

  Future<void> _saveSymptoms() async {
    if (!_canSave()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        _showErrorMessage('User not logged in');
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Format symptoms list with labels
      String? symptomsList;
      if (_selectedSymptoms.isNotEmpty) {
        symptomsList = _selectedSymptoms
            .map((value) => _getSymptomLabel(value))
            .join(': ');

        // Add notes if provided
        if (_notesController.text.isNotEmpty) {
          symptomsList += ': ${_notesController.text}';
        }
      }

      final success = await _trackerService.saveSymptoms(
        patientId: userId,
        date: today,
        status: !_noSymptoms,
        sList: symptomsList,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessMessage();
      } else {
        _showErrorMessage('Failed to save. Please try again.');
      }
    } catch (e) {
      print('Error saving symptoms: $e');
      if (mounted) {
        _showErrorMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Saved Successfully',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back to dashboard after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFEF4444),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Report Symptoms',
          style: TextStyle(
            color: Color(0xFF991B1B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.warning_amber_outlined,
                        color: Color(0xFFEF4444),
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Symptom Reporting',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Track any symptoms you\'re experiencing',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Question
                    const Text(
                      'Select all symptoms you\'re experiencing:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3B5D),
                      ),
                      textAlign: TextAlign.left,
                    ),

                    const SizedBox(height: 16),

                    // Symptoms Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _symptoms.length,
                      itemBuilder: (context, index) {
                        final symptom = _symptoms[index];
                        final isSelected = _selectedSymptoms.contains(
                          symptom['value'],
                        );
                        final symptomColor = symptom['color'] as Color;
                        return OutlinedButton(
                          onPressed: () => _toggleSymptom(symptom['value']!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            side: BorderSide(
                              color: isSelected
                                  ? symptomColor
                                  : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                            backgroundColor: isSelected
                                ? symptomColor
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            symptom['label']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    if (_selectedSymptoms.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      // Selected Symptoms
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Symptoms (${_selectedSymptoms.length}):',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSymptoms.map((symptomValue) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSymptomBgColor(symptomValue),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getSymptomColor(symptomValue),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getSymptomLabel(symptomValue),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getSymptomColor(symptomValue),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_selectedSymptoms.isNotEmpty) ...[
                const SizedBox(height: 16),

                // Additional Notes
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Describe when symptoms started, severity, or other relevant details',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_hasSeriousSymptoms()) ...[
                const SizedBox(height: 16),

                // Important Warning
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF991B1B),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Important: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    'You\'ve reported serious symptoms. Please contact your healthcare provider immediately if symptoms persist or worsen.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _selectNoSymptoms,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _noSymptoms
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF6B7280),
                          side: BorderSide(
                            color: _noSymptoms
                                ? const Color(0xFF6B7280)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          backgroundColor: _noSymptoms
                              ? const Color(0xFFF3F4F6)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canSave() ? _saveSymptoms : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSave()
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFD1D5DB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Symptoms',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
