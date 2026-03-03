import 'package:flutter/material.dart';
import 'package:app/services/tracker_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:intl/intl.dart';

class VitaminKScreen extends StatefulWidget {
  const VitaminKScreen({super.key});

  @override
  State<VitaminKScreen> createState() => _VitaminKScreenState();
}

class _VitaminKScreenState extends State<VitaminKScreen> {
  final _trackerService = TrackerService();
  String? _selectedAnswer;
  double _gramAmount = 50.0;
  bool _isLoading = false;

  bool _canSave() {
    return _selectedAnswer != null && !_isLoading;
  }

  Future<void> _saveRecord() async {
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

      final success = await _trackerService.saveVitaminK(
        patientId: userId,
        date: today,
        status: _selectedAnswer == 'Yes',
        weight: _selectedAnswer == 'Yes' ? _gramAmount : null,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessMessage();
      } else {
        _showErrorMessage('Failed to save. Please try again.');
      }
    } catch (e) {
      print('Error saving vitamin K: $e');
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
      backgroundColor: const Color(0xFFD1FAE5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF10B981),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Vitamin K Intake',
          style: TextStyle(
            color: Color(0xFF065F46),
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
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: Color(0xFF10B981),
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Green Leafy Vegetables',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Track your Vitamin K intake today',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Question
                    const Text(
                      'Did you eat green leafy vegetables today?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3B5D),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

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
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280),
                              side: BorderSide(
                                color: _selectedAnswer == 'Yes'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              backgroundColor: _selectedAnswer == 'Yes'
                                  ? const Color(0xFFD1FAE5)
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
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _selectedAnswer == 'No'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280),
                              side: BorderSide(
                                color: _selectedAnswer == 'No'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              backgroundColor: _selectedAnswer == 'No'
                                  ? const Color(0xFFD1FAE5)
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

              // Show content based on selection
              if (_selectedAnswer == 'Yes') ...[
                // Estimated weight card with slider
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated weight (grams)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF065F46),
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                          thumbColor: Colors.white,
                          overlayColor: const Color(
                            0xFF10B981,
                          ).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value: _gramAmount,
                          min: 0,
                          max: 200,
                          divisions: 40,
                          onChanged: (value) {
                            setState(() {
                              _gramAmount = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${_gramAmount.toInt()}g',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPortionLabel(_gramAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Note card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2B7EF8),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E40AF),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Note: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Green vegetables like spinach, kale, and broccoli contain Vitamin K, which can affect your warfarin dosage. Consistent intake is important.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_selectedAnswer == 'No') ...[
                // No intake message card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Center(
                    child: Text(
                      'No Vitamin K intake recorded for today',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSave() ? _saveRecord : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave()
                        ? const Color(0xFF10B981)
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
                              'Save Vitamin K Intake',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getPortionLabel(double grams) {
    if (grams < 30) {
      return 'Small portion';
    } else if (grams < 70) {
      return 'Medium portion';
    } else if (grams < 120) {
      return 'Large portion';
    } else {
      return 'Extra large portion';
    }
  }
}
