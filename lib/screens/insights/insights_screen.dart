import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/tracker_service.dart';
import '../../services/user_preferences.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final TrackerService _trackerService = TrackerService();

  bool _isLoading = true;
  String _status = '';
  List<String> _recommendations = [];
  List<Map<String, dynamic>> _trackingDataByDate = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patientId = await UserPreferences.getUserId();
      if (patientId == null) {
        print('No patient ID found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch both insights and tracking data
      final insights = await _trackerService.getOverallInsights(
        patientId: patientId,
      );

      final trackingData = await _trackerService.getPatientTrackingData(
        patientId: patientId,
      );

      if (insights != null) {
        setState(() {
          _status = insights['status'] ?? 'No status available';
          _recommendations = List<String>.from(
            insights['recommendations'] ?? [],
          );
        });
      }

      // Process tracking data - display all entries
      if (trackingData != null && trackingData.isNotEmpty) {
        List<Map<String, dynamic>> dateList = [];

        for (var dayData in trackingData) {
          dateList.add({
            'date': dayData['date'] ?? '',
            'extraDoseCount': (dayData['extraDose'] as List?)?.length ?? 0,
            'vitaminKTotal': _calculateVitaminKTotal(dayData['vitaminK']),
            'medicationCount': (dayData['medications'] as List?)?.length ?? 0,
            'symptomCount': (dayData['symptoms'] as List?)?.length ?? 0,
          });
        }

        // Sort by date (newest first)
        dateList.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          _trackingDataByDate = dateList;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateVitaminKTotal(dynamic vitaminKList) {
    if (vitaminKList == null) return 0.0;
    double total = 0.0;
    for (var vk in vitaminKList) {
      total += (vk['weight'] ?? 0.0) as double;
    }
    return total;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
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
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: const Text(
          'Tracker Insights',
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

              // Loading or Status Card
              if (_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INR Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _status.isNotEmpty
                                  ? _status
                                  : 'No data available',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Recommendations Card
              if (!_isLoading && _recommendations.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF2B7EF8),
                            size: 28,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        _recommendations.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _recommendations.length - 1
                                ? 12.0
                                : 0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF2B7EF8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _recommendations[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Recent Tracking Data
              const Text(
                'Recent Tracking Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3B5D),
                ),
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_trackingDataByDate.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text(
                      'No tracking data available',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                ...List.generate(_trackingDataByDate.length, (index) {
                  final dateData = _trackingDataByDate[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _trackingDataByDate.length - 1 ? 16.0 : 0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Color(0xFF2B7EF8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(dateData['date']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3B5D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          // Tracking Items
                          _buildTrackingItem(
                            color: const Color(0xFFEF4444),
                            label: 'Extra Doses',
                            value: '${dateData['extraDoseCount']}',
                            valueColor: dateData['extraDoseCount'] > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 12),
                          _buildTrackingItem(
                            color: const Color(0xFF10B981),
                            label: 'Vitamin K Intake',
                            value:
                                '${(dateData['vitaminKTotal'] as double).toStringAsFixed(1)}g',
                            valueColor: const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 12),
                          _buildTrackingItem(
                            color: const Color(0xFF9333EA),
                            label: 'Extra Medications',
                            value: '${dateData['medicationCount']}',
                            valueColor: dateData['medicationCount'] > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 12),
                          _buildTrackingItem(
                            color: const Color(0xFFEF4444),
                            label: 'Symptoms',
                            value: '${dateData['symptomCount']}',
                            valueColor: dateData['symptomCount'] > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Next Steps Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNextStepItem(
                      'Continue tracking your daily medication and diet consistently',
                    ),
                    const SizedBox(height: 12),
                    _buildNextStepItem(
                      'Monitor INR as scheduled by your healthcare provider',
                    ),
                    const SizedBox(height: 12),
                    _buildNextStepItem(
                      'Report any unusual symptoms immediately',
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

  Widget _buildTrackingItem({
    required Color color,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A3B5D)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.chevron_right, color: Color(0xFF2B7EF8), size: 20),
        const SizedBox(width: 8),
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
