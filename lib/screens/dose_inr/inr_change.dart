import 'package:flutter/material.dart';
import 'package:app/services/tracker_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:intl/intl.dart';

class InrChangeScreen extends StatefulWidget {
  final double currentInr;

  const InrChangeScreen({super.key, required this.currentInr});

  @override
  State<InrChangeScreen> createState() => _InrChangeScreenState();
}

class _InrChangeScreenState extends State<InrChangeScreen> {
  final _trackerService = TrackerService();
  final double _targetMin = 2.0;
  final double _targetMax = 3.0;

  bool _isLoading = true;
  String _inrStatus = 'Out of Range';
  String _primaryBehavior = '';
  double _primaryImpactScore = 0.0;
  double _probability = 0.0;
  List<Map<String, dynamic>> _otherBehaviors = [];
  Map<String, dynamic> _trackerSummary = {};

  @override
  void initState() {
    super.initState();
    _loadBehaviorAnalysis();
  }

  Future<void> _loadBehaviorAnalysis() async {
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
      final result = await _trackerService.getBehaviorAnalysis(
        patientId: userId,
        date: today,
        inrStatus: 1,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _inrStatus = result['inrStatus'] ?? 'Out of Range';

          final primaryBehavior = result['primaryBehavior'];
          if (primaryBehavior != null) {
            _primaryBehavior = primaryBehavior['behavior'] ?? '';
            _primaryImpactScore = (primaryBehavior['impact_score'] ?? 0.0)
                .toDouble();
          }

          _probability = (result['probability'] ?? 0.0).toDouble();

          final otherBehaviors = result['otherBehaviors'] as List?;
          if (otherBehaviors != null) {
            _otherBehaviors = otherBehaviors.cast<Map<String, dynamic>>();
          }

          _trackerSummary = result['trackerSummary'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Failed to load analysis data');
      }
    } catch (e) {
      print('Error loading behavior analysis: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('An error occurred while loading data');
      }
    }
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

  String _getImpactLevel(double impactScore) {
    if (impactScore >= 0.01) {
      return 'High';
    } else if (impactScore >= 0.005) {
      return 'Moderate';
    } else {
      return 'Low';
    }
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
          'INR Change Analysis',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B7EF8)),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Current INR Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B7EF8), Color(0xFF1E5FD9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current INR',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.currentInr.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Target Range: $_targetMin - $_targetMax',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _inrStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Analysis Complete Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEFFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle,
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
                                  'Analysis Complete',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Based on your tracked data',
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

                    const SizedBox(height: 16),

                    // Primary Factor Card
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Primary Factor',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3B5D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEAB308),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _primaryBehavior
                                            .split(' ')
                                            .take(3)
                                            .join(' '),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF78350F),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE68A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_getImpactLevel(_primaryImpactScore)}\nImpact',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF78350F),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _primaryBehavior,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF78350F),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Other Observations Card
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
                            'Other Observations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(_otherBehaviors.length, (index) {
                            final behavior = _otherBehaviors[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _otherBehaviors.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: _buildObservationItem(
                                behavior['behavior'] ?? '',
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tracked Data Summary Card
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
                            'Tracked Data Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDataRow(
                            'Missed Doses',
                            '${_trackerSummary['missedDoses'] ?? 0}',
                          ),
                          const Divider(height: 32, color: Color(0xFFE5E7EB)),
                          _buildDataRow(
                            'Extra Doses',
                            '${_trackerSummary['extraDoses'] ?? 0}',
                          ),
                          const Divider(height: 32, color: Color(0xFFE5E7EB)),
                          _buildDataRow(
                            'Vitamin K Intake',
                            _trackerSummary['vitaminKIntake'] ?? '0g',
                          ),
                          const Divider(height: 32, color: Color(0xFFE5E7EB)),
                          _buildDataRow(
                            'Extra Medication',
                            _trackerSummary['extraMedication'] ?? 'None',
                          ),
                          const Divider(height: 32, color: Color(0xFFE5E7EB)),
                          _buildDataRow(
                            'Symptoms Reported',
                            '${_trackerSummary['symptomsReported'] ?? 0}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clinical Summary Card
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
                            'Clinical Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      height: 1.6,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Primary Factor: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: _primaryBehavior),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      height: 1.6,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Impact Level: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _getImpactLevel(
                                          _primaryImpactScore,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      height: 1.6,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Recommendation: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Adjust warfarin dosing as calculated. Monitor INR more frequently. Contact your healthcare provider if INR remains outside target range.',
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

                    const SizedBox(height: 24),

                    // Back Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B7EF8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Back to Dose & INR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildObservationItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.chevron_right, color: Color(0xFF2B7EF8), size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3B5D),
          ),
        ),
      ],
    );
  }
}
