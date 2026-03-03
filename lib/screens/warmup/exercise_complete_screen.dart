import 'package:flutter/material.dart';
import 'monthly_analysis_screen.dart';
import '../dashboard/dashboard_screen.dart';

class ExerciseCompleteScreen extends StatelessWidget {
  final double? preExerciseSpo2;
  final double? preExercisePulse;
  final double? postExerciseSpo2;
  final double? postExercisePulse;
  final double distanceCovered;
  final int timeElapsed;
  final Set<String> stopReasons;

  const ExerciseCompleteScreen({
    super.key,
    this.preExerciseSpo2,
    this.preExercisePulse,
    this.postExerciseSpo2,
    this.postExercisePulse,
    required this.distanceCovered,
    required this.timeElapsed,
    required this.stopReasons,
  });

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _calculateAchievementPercentage() {
    const dailyTarget = 100.0; // 100m daily target
    return ((distanceCovered / dailyTarget) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final achievementPercentage = _calculateAchievementPercentage();

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Exercise Complete!',
          style: TextStyle(
            color: Color(0xFF10B981),
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

              // Success Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Target Achieved!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You completed your walking exercise',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Summary Card
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
                    const Text(
                      'Today\'s Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Distance Covered
                    _buildSummaryRow(
                      'Distance Covered',
                      '${distanceCovered.toStringAsFixed(0)}m',
                      Colors.black,
                    ),
                    const Divider(height: 32),

                    // Daily Target
                    _buildSummaryRow('Daily Target', '100m', Colors.black),
                    const Divider(height: 32),

                    // Achievement
                    _buildSummaryRow(
                      'Achievement',
                      '$achievementPercentage%',
                      const Color(0xFF10B981),
                    ),
                    const Divider(height: 32),

                    // Duration
                    _buildSummaryRow(
                      'Duration',
                      _formatDuration(timeElapsed),
                      Colors.black,
                    ),
                    const Divider(height: 32),

                    // Pre-Exercise SpO2
                    _buildSummaryRow(
                      'Pre-Exercise SpO₂',
                      preExerciseSpo2 != null
                          ? '${preExerciseSpo2!.toStringAsFixed(1)}%'
                          : 'N/A',
                      const Color(0xFF6B7280),
                    ),
                    const Divider(height: 32),

                    // Pre-Exercise Pulse
                    _buildSummaryRow(
                      'Pre-Exercise Pulse',
                      preExercisePulse != null
                          ? '${preExercisePulse!.toStringAsFixed(1)} bpm'
                          : 'N/A',
                      const Color(0xFF6B7280),
                    ),
                    const Divider(height: 32),

                    // Post-Exercise SpO2
                    _buildSummaryRow(
                      'Post-Exercise SpO₂',
                      postExerciseSpo2 != null
                          ? '${postExerciseSpo2!.toStringAsFixed(1)}%'
                          : 'N/A',
                      const Color(0xFF10B981),
                    ),
                    const Divider(height: 32),

                    // Post-Exercise Pulse
                    _buildSummaryRow(
                      'Post-Exercise Pulse',
                      postExercisePulse != null
                          ? '${postExercisePulse!.toStringAsFixed(1)} bpm'
                          : 'N/A',
                      const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Next Session Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEBFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2B7EF8), width: 2),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Session',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tomorrow\'s target: 110m',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B7EF8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Keep up the great work! You\'re progressing towards the 2km goal.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MonthlyAnalysisScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B7EF8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Monthly Analysis',
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
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
