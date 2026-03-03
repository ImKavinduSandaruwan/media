import 'dart:convert';
import 'package:app/api.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../../services/user_preferences.dart';
import '../dashboard/dashboard_screen.dart';

class MonthlyAnalysisScreen extends StatefulWidget {
  const MonthlyAnalysisScreen({super.key});

  @override
  State<MonthlyAnalysisScreen> createState() => _MonthlyAnalysisScreenState();
}

class _MonthlyAnalysisScreenState extends State<MonthlyAnalysisScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _weeklyData;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyData();
  }

  Future<void> _fetchWeeklyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .get(Uri.parse('$baseURL/health-factor/weekly/$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _weeklyData = data.isNotEmpty
              ? data.first as Map<String, dynamic>
              : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please check your network.';
        _isLoading = false;
      });
    }
  }

  // Helper getters with null safety
  double get _avgBeforeSpo2 =>
      (_weeklyData?['avgBeforeSpo2'] as num?)?.toDouble() ?? 0.0;
  double get _avgAfterSpo2 =>
      (_weeklyData?['avgAfterSpo2'] as num?)?.toDouble() ?? 0.0;
  double get _avgBeforeHr =>
      (_weeklyData?['avgBeforeHr'] as num?)?.toDouble() ?? 0.0;
  double get _avgAfterHr =>
      (_weeklyData?['avgAfterHr'] as num?)?.toDouble() ?? 0.0;
  double get _avgRun => (_weeklyData?['avgRun'] as num?)?.toDouble() ?? 0.0;
  String get _period => (_weeklyData?['period'] as String?) ?? '--';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7EF8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monthly Analysis',
          style: TextStyle(
            color: Color(0xFF2B7EF8),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B7EF8)),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchWeeklyData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7EF8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _weeklyData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    color: Color(0xFF6B7280),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No weekly data available yet.\nComplete a workout session to see your analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _fetchWeeklyData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7EF8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchWeeklyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Weekly Performance Header Card
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
                                Icons.trending_up,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Weekly Performance',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Week: $_period',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // This Week's Averages Card
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
                              'This Week\'s Averages',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SpO2 Before/After Row
                            Row(
                              children: [
                                Expanded(
                                  child: _avgStatCard(
                                    label: 'SpO₂ Before',
                                    value:
                                        '${_avgBeforeSpo2.toStringAsFixed(1)}%',
                                    icon: Icons.air,
                                    bgColor: const Color(0xFFDEEBFF),
                                    valueColor: const Color(0xFF2B7EF8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _avgStatCard(
                                    label: 'SpO₂ After',
                                    value:
                                        '${_avgAfterSpo2.toStringAsFixed(1)}%',
                                    icon: Icons.air,
                                    bgColor: const Color(0xFFD1FAE5),
                                    valueColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Heart Rate Before/After Row
                            Row(
                              children: [
                                Expanded(
                                  child: _avgStatCard(
                                    label: 'HR Before',
                                    value: '${_avgBeforeHr.toStringAsFixed(0)}',
                                    unit: 'bpm',
                                    icon: Icons.favorite,
                                    bgColor: const Color(0xFFFEE2E2),
                                    valueColor: const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _avgStatCard(
                                    label: 'HR After',
                                    value: '${_avgAfterHr.toStringAsFixed(0)}',
                                    unit: 'bpm',
                                    icon: Icons.favorite,
                                    bgColor: const Color(0xFFFEF3C7),
                                    valueColor: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Avg Run Distance
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.directions_walk,
                                    color: Color(0xFF10B981),
                                    size: 36,
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Avg Walk Distance',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_avgRun.toStringAsFixed(1)} m',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SpO2 Trend Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SpO₂ Trend',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.trending_up,
                                        color: Color(0xFF10B981),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Improving',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 2,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xFFE5E7EB),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xFFE5E7EB),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          const labels = ['Before', 'After'];
                                          if (value.toInt() >= 0 &&
                                              value.toInt() < labels.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                labels[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: 1,
                                  minY: 85,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        FlSpot(
                                          0,
                                          _avgBeforeSpo2.clamp(85, 100),
                                        ),
                                        FlSpot(1, _avgAfterSpo2.clamp(85, 100)),
                                      ],
                                      isCurved: true,
                                      color: const Color(0xFF2B7EF8),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: const Color(0xFF2B7EF8),
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                      ),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Before: ${_avgBeforeSpo2.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2B7EF8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'After: ${_avgAfterSpo2.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Normal range: 95-100%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Heart Rate Trend Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Heart Rate Trend',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.trending_up,
                                        color: Color(0xFFF59E0B),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Monitor',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 5,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xFFE5E7EB),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xFFE5E7EB),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          const days = [
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                            'Sat',
                                            'Sun',
                                          ];
                                          if (value.toInt() >= 0 &&
                                              value.toInt() < days.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                days[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: 1,
                                  minY:
                                      (_avgBeforeHr < _avgAfterHr
                                          ? _avgBeforeHr
                                          : _avgAfterHr) -
                                      10,
                                  maxY:
                                      (_avgBeforeHr > _avgAfterHr
                                          ? _avgBeforeHr
                                          : _avgAfterHr) +
                                      10,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        FlSpot(0, _avgBeforeHr),
                                        FlSpot(1, _avgAfterHr),
                                      ],
                                      isCurved: true,
                                      color: const Color(0xFFDC2626),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: const Color(0xFFDC2626),
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                      ),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Before: ${_avgBeforeHr.toStringAsFixed(0)} bpm',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'After: ${_avgAfterHr.toStringAsFixed(0)} bpm',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Normal range: 60-100 bpm',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Monthly Analysis Section
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
                            Row(
                              children: const [
                                Icon(
                                  Icons.trending_up,
                                  color: Color(0xFF2B7EF8),
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Monthly Analysis',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Based on your current progress trends:',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Expected SpO2 Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Expected SpO₂',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A3B5D),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF10B981),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Text(
                                          'Good',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF10B981),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: const Text(
                                          'Excellent oxygen saturation. Your SpO₂ levels are within the healthy range (≥95%). Continue your current exercise routine.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF1A3B5D),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Expected Heart Rate Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Expected Heart Rate',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A3B5D),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF10B981),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Text(
                                          'Good',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF10B981),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: const Text(
                                          'Excellent cardiovascular response. Heart rate is within optimal range (60-100 bpm). Your fitness is improving steadily.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF1A3B5D),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Clinical Insights Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEEBFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF2B7EF8),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF2B7EF8),
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Clinical Insights',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B7EF8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInsightItem(
                              'Your SpO₂ levels are within healthy range (95-100%)',
                            ),
                            _buildInsightItem(
                              'Heart rate shows good recovery adaptation',
                            ),
                            _buildInsightItem(
                              'Continue progressive distance increases',
                            ),
                            _buildInsightItem(
                              'Maintain consistent exercise schedule',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Monthly Progress Card
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
                              'Monthly Progress',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Total Sessions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Total Sessions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  '7/30 days',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 7 / 30,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1A3B5D),
                                ),
                                minHeight: 8,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Total Distance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Total Distance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  '1113m',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 1113 / 2000,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1A3B5D),
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Goal: 2000m',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Back to Home Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                              (route) => false,
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
                            'Back to Home',
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
            ), // closes RefreshIndicator
    );
  }

  Widget _avgStatCard({
    required String label,
    required String value,
    String? unit,
    required IconData icon,
    required Color bgColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: valueColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (unit != null)
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B7EF8),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2B7EF8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
