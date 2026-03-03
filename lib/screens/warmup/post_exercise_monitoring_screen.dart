import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'exercise_complete_screen.dart';
import '../../services/health_factor_service.dart';
import '../../services/user_preferences.dart';

class PostExerciseMonitoringScreen extends StatefulWidget {
  final double? preExerciseSpo2;
  final double? preExercisePulse;
  final double distanceCovered;
  final int timeElapsed;
  final Set<String> stopReasons;
  final int? healthFactorId;

  const PostExerciseMonitoringScreen({
    super.key,
    this.preExerciseSpo2,
    this.preExercisePulse,
    required this.distanceCovered,
    required this.timeElapsed,
    required this.stopReasons,
    this.healthFactorId,
  });

  @override
  State<PostExerciseMonitoringScreen> createState() =>
      _PostExerciseMonitoringScreenState();
}

class _PostExerciseMonitoringScreenState
    extends State<PostExerciseMonitoringScreen> {
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _spo2Controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _completeExercise() async {
    final spo2 = double.tryParse(_spo2Controller.text);
    final pulse = double.tryParse(_pulseController.text);

    if (spo2 == null || pulse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid SpO₂ and Pulse values'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user ID
      final userId = await UserPreferences.getUserId();

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
        return;
      }

      // Use userId as id (or healthFactorId if available)
      final idToUse = widget.healthFactorId ?? userId;

      print('=== Post-Exercise Monitoring: Preparing API Call ===');
      print(
        'Received vitals: preExerciseSpo2=${widget.preExerciseSpo2}, preExercisePulse=${widget.preExercisePulse}',
      );
      print('Entered vitals: postExerciseSpo2=$spo2, postExercisePulse=$pulse');
      print('Using ID: $idToUse, patientId: $userId');

      // Call update API with vitals (use 0 as fallback if pre-exercise vitals are missing)
      final result = await HealthFactorService.updateHealthFactor(
        id: idToUse,
        patientId: userId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        beforeSpo2: widget.preExerciseSpo2 ?? 0.0,
        beforeHr: widget.preExercisePulse ?? 0.0,
        afterSpo2: spo2,
        afterHr: pulse,
        run: widget.distanceCovered,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result['success']) {
          final responseData = result['data'];
          // Navigate to exercise complete screen with API response
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseCompleteScreen(
                preExerciseSpo2: responseData['beforeSpo2'],
                preExercisePulse: responseData['beforeHr'],
                postExerciseSpo2: responseData['afterSpo2'],
                postExercisePulse: responseData['aftereHr'], // API has typo
                distanceCovered: responseData['run'],
                timeElapsed: widget.timeElapsed,
                stopReasons: widget.stopReasons,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to save exercise data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Post-Exercise Monitoring',
          style: TextStyle(
            color: Color(0xFF2B7EF8),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Main Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEEBFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFF2B7EF8),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check Your Vitals',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3B5D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Measure after cool-down',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // SpO2 Input
                    const Text(
                      'SpO₂ (Oxygen Saturation) %',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _spo2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 98',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pulse Input
                    const Text(
                      'Pulse (Heart Rate) bpm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pulseController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 85',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Complete Exercise Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _completeExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            27,
                            101,
                            238,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Complete Exercise',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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
}
