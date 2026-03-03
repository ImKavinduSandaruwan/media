import 'package:flutter/material.dart';
import '../../services/health_factor_service.dart';
import '../../services/user_preferences.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _showContactDoctor = false;
  bool _showVitalsScreen = false;
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  String _vitalStatus = '';
  bool _showVitalWarning = false;

  // Store vitals data
  double? _savedSpo2;
  double? _savedPulse;
  int? _healthFactorId;
  bool _isInitializing = false;

  @override
  void dispose() {
    _spo2Controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkVitals() {
    final spo2 = double.tryParse(_spo2Controller.text);
    final pulse = double.tryParse(_pulseController.text);

    if (spo2 == null || pulse == null) {
      return;
    }

    setState(() {
      // Save the vitals data
      _savedSpo2 = spo2;
      _savedPulse = pulse;

      // Check if vitals are in safe range
      // Normal SpO2: 95-100%, Normal resting pulse: 60-100 bpm
      if (spo2 < 95 || pulse < 60 || pulse > 100) {
        _vitalStatus = 'Danger';
        _showVitalWarning = true;
      } else {
        _vitalStatus = 'Normal';
        _showVitalWarning = false;
      }
    });
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
        title: Text(
          _showVitalsScreen ? 'Pre-Exercise Vitals' : 'Pre-Exercise Screening',
          style: const TextStyle(
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

              // Show Vitals Screen if ready
              if (_showVitalsScreen) ...[
                _buildVitalsScreen(),
              ]
              // Show Safety Check Screen
              else ...[
                // Safety Check Card
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
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
                                  'Safety Check',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check for any symptoms before starting',
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
                      const SizedBox(height: 32),
                      const Text(
                        'Do you have any of these symptoms right now?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSymptomItem('Shortness of breath'),
                      const SizedBox(height: 16),
                      _buildSymptomItem('Chest pain'),
                      const SizedBox(height: 16),
                      _buildSymptomItem('Dizziness'),
                      const SizedBox(height: 16),
                      _buildSymptomItem('Palpitations'),
                      const SizedBox(height: 16),
                      _buildSymptomItem('Excessive fatigue'),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showContactDoctor = true;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 2,
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Yes, I have symptoms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isInitializing
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isInitializing = true;
                                      });

                                      // Get user ID
                                      final userId =
                                          await UserPreferences.getUserId();
                                      if (userId == null) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'User not logged in',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          setState(() {
                                            _isInitializing = false;
                                          });
                                        }
                                        return;
                                      }

                                      // Initialize health factor session
                                      final result =
                                          await HealthFactorService.initializeSession(
                                            userId,
                                          );

                                      if (mounted) {
                                        setState(() {
                                          _isInitializing = false;
                                        });

                                        if (result['success']) {
                                          final data = result['data'];
                                          _healthFactorId = data['id'];
                                          setState(() {
                                            _showVitalsScreen = true;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                result['error'] ??
                                                    'Failed to initialize session',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isInitializing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      "No, I'm ready",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // Contact Doctor Warning
                      if (_showContactDoctor) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Important:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'You should not exercise if you have any of these symptoms. Please rest and contact your healthcare provider if symptoms persist.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7F1D1D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Contact doctor functionality
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.phone, size: 20),
                                  label: const Text(
                                    'Contact Doctor',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsScreen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEBFF),
                  borderRadius: BorderRadius.circular(12),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Measure before starting exercise',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'SpO₂ (Oxygen Saturation) %',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3B5D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _spo2Controller,
            keyboardType: TextInputType.number,
            onChanged: (value) => _checkVitals(),
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
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pulse (Heart Rate) bpm',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3B5D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pulseController,
            keyboardType: TextInputType.number,
            onChanged: (value) => _checkVitals(),
            decoration: InputDecoration(
              hintText: 'e.g., 72',
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
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Warning
          if (_vitalStatus == 'Danger') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Status: Danger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // Always save vitals before navigation
                final spo2 = double.tryParse(_spo2Controller.text);
                final pulse = double.tryParse(_pulseController.text);

                if (spo2 != null && pulse != null) {
                  setState(() {
                    _savedSpo2 = spo2;
                    _savedPulse = pulse;
                  });
                }

                if (_showVitalWarning && _vitalStatus == 'Danger') {
                  // Show warning dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                              'Warning: Abnormal Vitals',
                              style: TextStyle(
                                color: Color(0xFF1A3B5D),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Your vitals are outside safe range. Consider resting and contact your healthcare provider if needed.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Contact Doctor',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/warmup',
                              arguments: {
                                'spo2': _savedSpo2,
                                'pulse': _savedPulse,
                                'healthFactorId': _healthFactorId,
                              },
                            );
                          },
                          child: const Text(
                            'Continue Anyway',
                            style: TextStyle(
                              color: Color(0xFF2B7EF8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  print('=== Recovery -> Warmup Navigation ===');
                  print(
                    'Passing vitals: spo2=$_savedSpo2, pulse=$_savedPulse, healthFactorId=$_healthFactorId',
                  );
                  Navigator.pushNamed(
                    context,
                    '/warmup',
                    arguments: {
                      'spo2': _savedSpo2,
                      'pulse': _savedPulse,
                      'healthFactorId': _healthFactorId,
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7EF8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.directions_run, size: 22),
              label: const Text(
                'Continue to Warm-Up',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(String symptom) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            symptom,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A3B5D)),
          ),
        ],
      ),
    );
  }
}
