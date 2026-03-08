import 'package:flutter/material.dart';
import 'dart:async';
import 'walking_exercise_screen.dart';

class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  int _currentExercise = 1;
  final int _totalExercises = 8;
  // 8 exercises in 300s total: exercises 1-7 = 37s, exercise 8 = 38+1 = 41s (to sum to 300)
  // 7 * 37 = 259, last = 300 - 259 = 41
  static const List<int> _exerciseDurations = [37, 37, 37, 37, 37, 37, 37, 41];
  int _secondsRemaining = 37; // per-exercise countdown
  int _totalSecondsRemaining = 300; // overall 5-min countdown
  Timer? _timer;
  double? _spo2;
  double? _pulse;
  int? _healthFactorId;

  final List<Map<String, dynamic>> _exercises = [
    {'name': 'Slow Breathing + Shoulder Rolls', 'completed': false},
    {'name': 'Neck Mobility', 'completed': false},
    {'name': 'Arm Circles', 'completed': false},
    {'name': 'Marching in Place', 'completed': false},
    {'name': 'Heel Raises / Toe Taps', 'completed': false},
    {'name': 'Side-to-Side Step Touch', 'completed': false},
    {'name': 'Gentle Leg Swings', 'completed': false},
    {'name': 'Light Stretching (Hamstrings, Chest, Side)', 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Get vitals data from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        print('=== Warmup Screen Received Arguments ===');
        print(
          'spo2: ${args['spo2']}, pulse: ${args['pulse']}, healthFactorId: ${args['healthFactorId']}',
        );
        setState(() {
          _spo2 = args['spo2'] as double?;
          _pulse = args['pulse'] as double?;
          _healthFactorId = args['healthFactorId'] as int?;
        });
      } else {
        print('=== Warmup Screen: No arguments received ===');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          if (_totalSecondsRemaining > 0) _totalSecondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _moveToNextExercise();
      }
    });
  }

  void _moveToNextExercise() {
    if (_currentExercise < _totalExercises) {
      setState(() {
        _exercises[_currentExercise - 1]['completed'] = true;
        _currentExercise++;
        _secondsRemaining = _exerciseDurations[_currentExercise - 1];
      });
      _startTimer();
    }
  }

  double get _progress => _currentExercise / _totalExercises;
  int get _overallProgress => (_progress * 100).round();

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
            color: Color(0xFFF97316),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Warm-Up',
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

              // Warm-Up Routine Card
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.air,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Warm-Up Routine',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Prepare your body for walking',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Exercise Progress Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercise $_currentExercise of $_totalExercises',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'Total: ${_formatTime(_totalSecondsRemaining)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFF97316),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A3B5D),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current Exercise Display
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _exercises[_currentExercise - 1]['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatTime(_secondsRemaining),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const Text(
                            'remaining',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Exercise List
                    ..._exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      final isCompleted = exercise['completed'];
                      final isCurrent = index == _currentExercise - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFFD1FAE5)
                                : isCurrent
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFD1D5DB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  exercise['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isCompleted
                                        ? const Color(0xFF059669)
                                        : isCurrent
                                        ? const Color(0xFF78350F)
                                        : const Color(0xFF6B7280),
                                    fontWeight: isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A3B5D),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Overall Progress: $_overallProgress%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print(
                            '=== Warmup -> Walking Exercise Navigation ===',
                          );
                          print(
                            'Passing vitals: spo2=$_spo2, pulse=$_pulse, healthFactorId=$_healthFactorId',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalkingExerciseScreen(
                                spo2: _spo2,
                                pulse: _pulse,
                                healthFactorId: _healthFactorId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 24),
                        label: const Text(
                          'Continue to Walking',
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
