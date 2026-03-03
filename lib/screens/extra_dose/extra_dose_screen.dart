import 'package:flutter/material.dart';
import 'package:app/services/tracker_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:intl/intl.dart';

class ExtraDoseScreen extends StatefulWidget {
  const ExtraDoseScreen({super.key});

  @override
  State<ExtraDoseScreen> createState() => _ExtraDoseScreenState();
}

class _ExtraDoseScreenState extends State<ExtraDoseScreen> {
  final _trackerService = TrackerService();
  String? _selectedAnswer;
  final _doseAmountController = TextEditingController();
  TimeOfDay? _selectedTime;
  String? _selectedReason;
  bool _isLoading = false;

  @override
  void dispose() {
    _doseAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _canSave() {
    if (_selectedAnswer == 'Yes') {
      return _doseAmountController.text.isNotEmpty &&
          _selectedTime != null &&
          _selectedReason != null &&
          !_isLoading;
    } else if (_selectedAnswer == 'No') {
      return !_isLoading;
    }
    return false;
  }

  Future<void> _saveChanges() async {
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

      // Parse dose amount
      double? doseAmount;
      String? time;
      String? reason;

      if (_selectedAnswer == 'Yes') {
        doseAmount = double.tryParse(_doseAmountController.text);
        if (doseAmount == null) {
          _showErrorMessage('Please enter a valid dose amount');
          return;
        }

        // Format time as HH:mm:ss
        if (_selectedTime != null) {
          final hour = _selectedTime!.hour.toString().padLeft(2, '0');
          final minute = _selectedTime!.minute.toString().padLeft(2, '0');
          time = '$hour:$minute:00';
        }

        reason = _selectedReason;
      }

      final success = await _trackerService.saveExtraDose(
        patientId: userId,
        date: today,
        status: _selectedAnswer == 'Yes',
        doseAmount: doseAmount,
        time: time,
        reason: reason,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessMessage();
      } else {
        _showErrorMessage('Failed to save. Please try again.');
      }
    } catch (e) {
      print('Error saving extra dose: $e');
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
        backgroundColor: const Color(0xFF10B981),
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
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2B7EF8),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Extra Dose Taken',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
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

              // Important Warning Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Important',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF92400E),
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Only take extra doses of warfarin if instructed by your healthcare provider. ',
                                ),
                                TextSpan(
                                  text:
                                      'Record any additional doses here for accurate tracking.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Question Card
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Color(0xFFF59E0B),
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Question
                    const Text(
                      'Did you take an extra dose today?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Yes/No Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedAnswer = 'Yes';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _selectedAnswer == 'Yes'
                                  ? const Color(0xFF2B7EF8)
                                  : const Color(0xFF6B7280),
                              side: BorderSide(
                                color: _selectedAnswer == 'Yes'
                                    ? const Color(0xFF2B7EF8)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              backgroundColor: _selectedAnswer == 'Yes'
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Yes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedAnswer = 'No';
                                // Clear fields when No is selected
                                _doseAmountController.clear();
                                _selectedTime = null;
                                _selectedReason = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _selectedAnswer == 'No'
                                  ? const Color(0xFF2B7EF8)
                                  : const Color(0xFF6B7280),
                              side: BorderSide(
                                color: _selectedAnswer == 'No'
                                    ? const Color(0xFF2B7EF8)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              backgroundColor: _selectedAnswer == 'No'
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'No',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Show Save Record button when No is selected
              if (_selectedAnswer == 'No') ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSave() ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7EF8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
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
                        : const Text(
                            'Save Record',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Show additional fields only when "Yes" is selected
              if (_selectedAnswer == 'Yes') ...[
                // Dose Amount Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dose Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _doseAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            setState(
                              () {},
                            ); // Refresh to update save button state
                          },
                          decoration: const InputDecoration(
                            hintText: 'e.g., 5mg, 2.5mg',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the amount of extra warfarin taken',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Time of Extra Dose
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time of Extra Dose',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatTime(_selectedTime).isEmpty
                                    ? ''
                                    : _formatTime(_selectedTime),
                                style: TextStyle(
                                  color: _selectedTime == null
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1A3B5D),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reason for Extra Dose
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for Extra Dose',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReasonOption('Doctor\'s instruction'),
                      const SizedBox(height: 8),
                      _buildReasonOption('Missed previous dose'),
                      const SizedBox(height: 8),
                      _buildReasonOption('Low INR reading'),
                      const SizedBox(height: 8),
                      _buildReasonOption('Scheduled adjustment'),
                      const SizedBox(height: 8),
                      _buildReasonOption('Other'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Monitoring Required Warning
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
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monitoring Required',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF991B1B),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Taking extra doses increases your INR and bleeding risk. ',
                                  ),
                                  TextSpan(
                                    text:
                                        'Monitor for any unusual bleeding or bruising and contact your healthcare provider if concerned.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSave() ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSave()
                          ? const Color(0xFF2B7EF8)
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
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // Information Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2B7EF8), width: 2),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'When to Take Extra Doses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoPoint(
                      'Only take extra doses as prescribed by your doctor',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoPoint(
                      'Usually given for low INR readings or missed doses',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoPoint(
                      'Never double dose without medical guidance',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoPoint(
                      'Schedule INR check after dose adjustments',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF2B7EF8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1A3B5D),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonOption(String reason) {
    final isSelected = _selectedReason == reason;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B7EF8) : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF1A3B5D)
                      : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2B7EF8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
