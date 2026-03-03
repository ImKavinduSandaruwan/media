import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'stop_reason_screen.dart';
import 'cool_down_screen.dart';

class WalkingExerciseScreen extends StatefulWidget {
  final double? spo2;
  final double? pulse;
  final int? healthFactorId;

  const WalkingExerciseScreen({
    super.key,
    this.spo2,
    this.pulse,
    this.healthFactorId,
  });

  @override
  State<WalkingExerciseScreen> createState() => _WalkingExerciseScreenState();
}

class _WalkingExerciseScreenState extends State<WalkingExerciseScreen> {
  int _secondsRemaining = 1800; // 30 minutes in seconds
  Timer? _timer;
  bool _isRunning = true;
  bool _isPaused = false;
  double _distanceCovered = 0.0; // in meters
  final double _dailyTarget = 100.0; // 100 meters target

  // GPS tracking
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  bool _locationEnabled = false;
  String _locationStatus = 'Initializing GPS...';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services disabled. Please enable GPS.';
        });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus =
              'Location permission permanently denied. Please enable in Settings.';
        });
        return;
      }

      // Get initial position
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _locationEnabled = true;
        _locationStatus = 'GPS tracking active';
      });

      // Start listening to position updates
      _startLocationStream();
    } catch (e) {
      setState(() {
        _locationStatus = 'GPS error: ${e.toString().substring(0, 50)}';
      });
      print('Location init error: $e');
    }
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Update every 2 meters of movement
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isPaused || !_isRunning) return;

            if (_lastPosition != null) {
              // Calculate distance between last and current position
              final distance = Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                position.latitude,
                position.longitude,
              );

              // Only add if reasonable movement (filter GPS noise, ignore jumps > 50m)
              if (distance > 0.5 && distance < 50) {
                setState(() {
                  _distanceCovered += distance;
                });
              }
            }

            _lastPosition = position;
          },
          onError: (error) {
            print('Location stream error: $error');
            setState(() {
              _locationStatus = 'GPS signal lost. Reconnecting...';
            });
          },
        );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && !_isPaused) {
        setState(() {
          _secondsRemaining--;
        });
      } else if (_secondsRemaining == 0) {
        _timer?.cancel();
        _completeWalking();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Stop Exercise?',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to stop your walking exercise?',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWalking();
            },
            child: const Text(
              'Stop',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeWalking() {
    _timer?.cancel();
    _positionStream?.cancel();
    setState(() {
      _isRunning = false;
    });

    // Navigate to stop reason screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StopReasonScreen(
          spo2: widget.spo2,
          pulse: widget.pulse,
          distanceCovered: _distanceCovered,
          timeElapsed: 1800 - _secondsRemaining,
          healthFactorId: widget.healthFactorId,
        ),
      ),
    );
  }

  void _handleEmergency() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFEE2E2),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Emergency',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you\'re experiencing:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3B5D),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• Chest pain or pressure\n• Severe shortness of breath\n• Dizziness or fainting\n• Irregular heartbeat',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            SizedBox(height: 16),
            Text(
              'Stop exercising immediately and seek medical help.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPaused = false;
              });
            },
            child: const Text(
              'Resume Exercise',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement emergency contact
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text(
              'Call for Help',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double get _progressPercentage => ((1800 - _secondsRemaining) / 1800) * 100;

  int get _targetPercentage =>
      ((_distanceCovered / _dailyTarget) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walking Exercise',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay at a comfortable pace',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _handleEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text(
                      'Emergency',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main Timer Card
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Timer Card
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
                            // Timer Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              'Time Remaining',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Timer Display
                            Text(
                              _formatTime(_secondsRemaining),
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (_progressPercentage / 100),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 12,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              '${_progressPercentage.toStringAsFixed(0)}% Complete',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Distance Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text(
                              'Distance Covered',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // GPS Status indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _locationEnabled
                                      ? Icons.gps_fixed
                                      : Icons.gps_off,
                                  size: 14,
                                  color: _locationEnabled
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _locationStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _locationEnabled
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_distanceCovered.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Daily Target: ${_dailyTarget.toStringAsFixed(0)}m ($_targetPercentage%)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (_distanceCovered / _dailyTarget).clamp(
                                  0.0,
                                  1.0,
                                ),
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _distanceCovered >= _dailyTarget
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF1A3B5D),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Control Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _togglePause,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                size: 24,
                              ),
                              label: Text(
                                _isPaused ? 'Resume' : 'Pause',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _stopExercise,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.stop, size: 24),
                              label: const Text(
                                'Stop',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Safety Guidelines Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEEBFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Safety Guidelines',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildGuidelineItem('Walk on flat, stable ground'),
                            const SizedBox(height: 10),
                            _buildGuidelineItem('Do not hold your breath'),
                            const SizedBox(height: 10),
                            _buildGuidelineItem('Maintain proper hydration'),
                            const SizedBox(height: 10),
                            _buildGuidelineItem(
                              'Stop immediately if you feel unwell',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            _positionStream?.cancel();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoolDownScreen(
                                  spo2: widget.spo2,
                                  pulse: widget.pulse,
                                  distanceCovered: _distanceCovered,
                                  timeElapsed: 1800 - _secondsRemaining,
                                  stopReasons: {},
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
                          icon: const Icon(Icons.check_circle, size: 24),
                          label: const Text(
                            'Continue to Cool-Down',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF2B7EF8),
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A3B5D)),
          ),
        ),
      ],
    );
  }
}
