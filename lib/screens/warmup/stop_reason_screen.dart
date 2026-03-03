import 'package:flutter/material.dart';
import 'cool_down_screen.dart';

class StopReasonScreen extends StatefulWidget {
  final double? spo2;
  final double? pulse;
  final double distanceCovered;
  final int timeElapsed;
  final int? healthFactorId;

  const StopReasonScreen({
    super.key,
    this.spo2,
    this.pulse,
    required this.distanceCovered,
    required this.timeElapsed,
    this.healthFactorId,
  });

  @override
  State<StopReasonScreen> createState() => _StopReasonScreenState();
}

class _StopReasonScreenState extends State<StopReasonScreen> {
  final List<String> _reasons = [
    'Chest pain',
    'Dizziness',
    'Shortness of breath',
    'Palpitations',
    'Excessive fatigue',
    'Swelling',
    'Heaviness',
  ];

  final Set<String> _selectedReasons = {};

  void _handleSkip() {
    // Navigate to cool down without reasons
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CoolDownScreen(
          spo2: widget.spo2,
          pulse: widget.pulse,
          distanceCovered: widget.distanceCovered,
          timeElapsed: widget.timeElapsed,
          stopReasons: {},
          healthFactorId: widget.healthFactorId,
        ),
      ),
    );
  }

  void _handleContinue() {
    // Navigate to cool down with selected reasons
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CoolDownScreen(
          spo2: widget.spo2,
          pulse: widget.pulse,
          distanceCovered: widget.distanceCovered,
          timeElapsed: widget.timeElapsed,
          stopReasons: _selectedReasons,
          healthFactorId: widget.healthFactorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Stop Reason',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why did you stop?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Optional - Select if applicable',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Reason Options
                ...List.generate(_reasons.length, (index) {
                  final reason = _reasons[index];
                  final isSelected = _selectedReasons.contains(reason);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedReasons.remove(reason);
                          } else {
                            _selectedReasons.add(reason);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFDEEBFF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2B7EF8)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2B7EF8)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2B7EF8)
                                      : const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? const Color(0xFF1A3B5D)
                                      : const Color(0xFF374151),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B7EF8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }
}
