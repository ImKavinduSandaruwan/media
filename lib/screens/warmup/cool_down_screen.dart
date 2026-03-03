import 'package:flutter/material.dart';
import 'dart:async';
import 'post_exercise_monitoring_screen.dart';

class CoolDownScreen extends StatefulWidget {
  final double? spo2;
  final double? pulse;
  final double distanceCovered;
  final int timeElapsed;
  final Set<String> stopReasons;
  final int? healthFactorId;

  const CoolDownScreen({
    super.key,
    this.spo2,
    this.pulse,
    required this.distanceCovered,
    required this.timeElapsed,
    required this.stopReasons,
    this.healthFactorId,
  });

  @override
  State<CoolDownScreen> createState() => _CoolDownScreenState();
}

class _CoolDownScreenState extends State<CoolDownScreen> {
  int _currentExercise = 1;
  final int _totalExercises = 5;
  int _secondsRemaining = 60;
  Timer? _timer;

  final List<Map<String, dynamic>> _exercises = [
    {'name': 'Slow Walking / Marching', 'completed': false, 'duration': 60},
    {'name': 'Deep Breathing', 'completed': false, 'duration': 60},
    {
      'name': 'Calf Stretch (30 sec each leg)',
      'completed': false,
      'duration': 60,
    },
    {'name': 'Hamstring Stretch', 'completed': false, 'duration': 60},
    {'name': 'Shoulder & Chest Stretch', 'completed': false, 'duration': 60},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
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
        _secondsRemaining = _exercises[_currentExercise - 1]['duration'];
      });
      _startTimer();
    } else {
      // All exercises complete
      setState(() {
        _exercises[_currentExercise - 1]['completed'] = true;
      });
    }
  }

  double get _exerciseProgress => _currentExercise / _totalExercises;
  int get _overallProgress => (_exerciseProgress * 100).round();

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentExerciseName = _exercises[_currentExercise - 1]['name'];

    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Cool Down',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B7EF8), Color(0xFF1E6FE8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.air,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cool Down Routine',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recover safely after exercise',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
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
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_secondsRemaining > 0
                            ? (60 - _secondsRemaining) / 60
                            : 1.0),
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EBF0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentExerciseName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B7EF8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_secondsRemaining',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B7EF8),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'seconds remaining',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Exercise List
                    ...List.generate(_exercises.length, (index) {
                      final exercise = _exercises[index];
                      final isCurrentExercise = index == _currentExercise - 1;
                      final isCompleted = exercise['completed'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentExercise
                                ? const Color(0xFFDEEBFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentExercise
                                  ? const Color(0xFF2B7EF8)
                                  : const Color(0xFFE5E7EB),
                              width: isCurrentExercise ? 2 : 1,
                            ),
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
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: isCompleted
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
                                  exercise['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isCurrentExercise
                                        ? const Color(0xFF1A3B5D)
                                        : const Color(0xFF6B7280),
                                    fontWeight: isCurrentExercise
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

                    // Overall Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _exerciseProgress,
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
                          _timer?.cancel();
                          print(
                            '=== Cool Down -> Post-Exercise Monitoring Navigation ===',
                          );
                          print(
                            'Passing vitals: spo2=${widget.spo2}, pulse=${widget.pulse}, healthFactorId=${widget.healthFactorId}',
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostExerciseMonitoringScreen(
                                    preExerciseSpo2: widget.spo2,
                                    preExercisePulse: widget.pulse,
                                    distanceCovered: widget.distanceCovered,
                                    timeElapsed: widget.timeElapsed,
                                    stopReasons: widget.stopReasons,
                                    healthFactorId: widget.healthFactorId,
                                  ),
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
                        icon: const Icon(Icons.favorite, size: 24),
                        label: const Text(
                          'Continue to Vitals Check',
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
