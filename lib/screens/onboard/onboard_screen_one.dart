import 'package:flutter/material.dart';

class OnboardScreenOne extends StatefulWidget {
  const OnboardScreenOne({super.key});

  @override
  State<OnboardScreenOne> createState() => _OnboardScreenOneState();
}

class _OnboardScreenOneState extends State<OnboardScreenOne> {
  TimeOfDay? _stopFoodTime;
  TimeOfDay? _takeWarfarinTime;
  TimeOfDay? _startFoodTime;
  bool _enableAlarms = false;
  bool _pushNotifications = false;

  Future<void> _selectTime(BuildContext context, String timeType) async {
    TimeOfDay? initialTime;
    if (timeType == 'stopFood') {
      initialTime = _stopFoodTime;
    } else if (timeType == 'takeWarfarin') {
      initialTime = _takeWarfarinTime;
    } else if (timeType == 'startFood') {
      initialTime = _startFoodTime;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (timeType == 'stopFood') {
          _stopFoodTime = picked;
          // Auto-calculate start food time (1 hour after warfarin)
          if (_takeWarfarinTime != null) {
            final warfarinHour = _takeWarfarinTime!.hour;
            final warfarinMinute = _takeWarfarinTime!.minute;
            final newHour = (warfarinHour + 1) % 24;
            _startFoodTime = TimeOfDay(hour: newHour, minute: warfarinMinute);
          }
        } else if (timeType == 'takeWarfarin') {
          _takeWarfarinTime = picked;
          // Auto-calculate start food time (1 hour after warfarin)
          final newHour = (picked.hour + 1) % 24;
          _startFoodTime = TimeOfDay(hour: newHour, minute: picked.minute);
        } else if (timeType == 'startFood') {
          _startFoodTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
          'Setup Your Schedule',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressDot(true),
                _buildProgressLine(true),
                _buildProgressDot(false),
                _buildProgressLine(false),
                _buildProgressDot(false),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Daily Schedule Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF2B7EF8),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Daily Schedule',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Set up your medication and meal times',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Stop Food Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                  children: [
                                    TextSpan(text: 'Stop Food Time '),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    TextSpan(
                                      text: '  (Before warfarin)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, 'stopFood'),
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
                                      Text(
                                        _formatTime(_stopFoodTime).isEmpty
                                            ? ''
                                            : _formatTime(_stopFoodTime),
                                        style: TextStyle(
                                          color: _stopFoodTime == null
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF1A3B5D),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.access_time,
                                        color: Color(0xFF9CA3AF),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Stop eating before taking warfarin',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Take Warfarin Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                  children: [
                                    TextSpan(text: 'Take Warfarin Time '),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    TextSpan(
                                      text: '  (1-hour window)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF2B7EF8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () =>
                                    _selectTime(context, 'takeWarfarin'),
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
                                      Text(
                                        _formatTime(_takeWarfarinTime).isEmpty
                                            ? ''
                                            : _formatTime(_takeWarfarinTime),
                                        style: TextStyle(
                                          color: _takeWarfarinTime == null
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF1A3B5D),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.access_time,
                                        color: Color(0xFF9CA3AF),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Must be taken within 1 hour of this time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Start Food Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                  children: [
                                    TextSpan(text: 'Start Food Time  '),
                                    TextSpan(
                                      text: '(Auto-adjusted)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
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
                                    Text(
                                      _formatTime(_startFoodTime).isEmpty
                                          ? ''
                                          : _formatTime(_startFoodTime),
                                      style: TextStyle(
                                        color: _startFoodTime == null
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF1A3B5D),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Automatically 1 hour after warfarin dose',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF2B7EF8),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3B5D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Enable Alarms
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Enable Alarms',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3B5D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Audio alerts for medication times',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _enableAlarms,
                                onChanged: (value) {
                                  setState(() {
                                    _enableAlarms = value;
                                  });
                                },
                                activeColor: const Color(0xFF2B7EF8),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Push Notifications
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Push Notifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3B5D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Reminders and health updates',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _pushNotifications,
                                onChanged: (value) {
                                  setState(() {
                                    _pushNotifications = value;
                                  });
                                },
                                activeColor: const Color(0xFF2B7EF8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Complete Setup Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Complete Setup',
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: isActive ? 12 : 10,
      height: isActive ? 12 : 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2B7EF8) : const Color(0xFFD1D5DB),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 60,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2B7EF8) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
