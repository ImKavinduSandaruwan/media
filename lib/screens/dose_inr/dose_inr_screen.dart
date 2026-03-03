import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/services/tracker_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:app/screens/dose_inr/inr_change.dart';
import 'package:intl/intl.dart';

class DoseInrScreen extends StatefulWidget {
  const DoseInrScreen({super.key});

  @override
  State<DoseInrScreen> createState() => _DoseInrScreenState();
}

class _DoseInrScreenState extends State<DoseInrScreen> {
  final _trackerService = TrackerService();
  final TextEditingController _inrController = TextEditingController();
  final double _currentInr = 2.3;
  final double _targetMin = 2.0;
  final double _targetMax = 3.0;

  bool _showDosePrediction = false;
  double _enteredInr = 0.0;
  double _recommendedDose = 0.0;
  String _riskLevel = '';
  String _actionRequired = '';
  int _nextCheckDays = 7;
  bool _isLoading = false;
  bool _isApproved = false;

  // INR Trend data
  List<Map<String, dynamic>> _inrTrendData = [];
  bool _isLoadingTrend = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 60));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInrTrendData();
  }

  @override
  void dispose() {
    _inrController.dispose();
    super.dispose();
  }

  Future<void> _loadInrTrendData() async {
    setState(() {
      _isLoadingTrend = true;
    });

    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        setState(() {
          _isLoadingTrend = false;
        });
        return;
      }

      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final result = await _trackerService.getInrRange(
        patientId: userId,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _inrTrendData = result.cast<Map<String, dynamic>>();
          _isLoadingTrend = false;
        });
      } else {
        setState(() {
          _inrTrendData = [];
          _isLoadingTrend = false;
        });
      }
    } catch (e) {
      print('Error loading INR trend data: $e');
      if (mounted) {
        setState(() {
          _inrTrendData = [];
          _isLoadingTrend = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B7EF8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A3B5D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadInrTrendData();
    }
  }

  List<FlSpot> _getInrDataFromApi() {
    if (_inrTrendData.isEmpty) return [];

    return List.generate(_inrTrendData.length, (index) {
      final inr = (_inrTrendData[index]['inr'] ?? 0.0).toDouble();
      return FlSpot(index.toDouble(), inr);
    });
  }

  Future<void> _calculateDose() async {
    if (_inrController.text.isEmpty) {
      _showErrorMessage('Please enter an INR value');
      return;
    }

    final inr = double.tryParse(_inrController.text);
    if (inr == null || inr <= 0) {
      _showErrorMessage('Please enter a valid INR value');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        _showErrorMessage('User not logged in');
        return;
      }

      final result = await _trackerService.calculateInrDose(
        patientId: userId,
        inr: inr,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _enteredInr = (result['inr'] ?? inr).toDouble();
          _recommendedDose = (result['dose'] ?? 0.0).toDouble();

          // Map action to user-friendly text
          final action = result['action'] ?? 'MAINTAIN';
          _actionRequired = _getActionText(action);

          // Set risk based on action: MAINTAIN = Normal, otherwise High Risk
          if (action.toUpperCase() == 'MAINTAIN') {
            _riskLevel = 'Normal';
          } else {
            _riskLevel = 'High Risk';
          }

          // Get next check days from API, default to 7 if null
          _nextCheckDays = result['nextcheck'] ?? 7;

          // Get approval status
          _isApproved = result['isApproved'] ?? false;

          _showDosePrediction = true;
        });
      } else {
        _showErrorMessage('Failed to calculate dose. Please try again.');
      }
    } catch (e) {
      print('Error calculating dose: $e');
      if (mounted) {
        _showErrorMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getActionText(String action) {
    switch (action.toUpperCase()) {
      case 'INCREASE':
        return 'Increase dose';
      case 'DECREASE':
        return 'Decrease dose';
      case 'MAINTAIN':
        return 'Maintain current dose';
      default:
        return 'Maintain current dose';
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
          'Dose & INR',
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
                  children: [
                    Expanded(
                      child: Column(
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
                            _currentInr.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_currentInr - 1) / 3,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target: $_targetMin - $_targetMax',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Enter Latest INR Value Card
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
                      'Enter Latest INR Value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'INR Value',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3B5D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inrController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., 2.5',
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateDose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B7EF8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Calculate Recommended Dose',
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

              const SizedBox(height: 16),

              // Dose Prediction Card (shown after calculation)
              if (_showDosePrediction) ...[
                // High Risk Warning
                if (_riskLevel == 'High Risk') ...[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your INR is outside the safe range.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please review the analysis and consider consulting your clinician.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(
                                    0xFF991B1B,
                                  ).withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dose Prediction Card
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
                          const Text(
                            'Dose Prediction',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5D),
                            ),
                          ),
                          Row(
                            children: [
                              if (_isApproved)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF059669),
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Approved',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isApproved) const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _riskLevel == 'Normal'
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _riskLevel,
                                  style: TextStyle(
                                    color: _riskLevel == 'Normal'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current INR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _enteredInr.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A3B5D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recommended Dose',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _recommendedDose.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          'mg',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Action Required',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _actionRequired,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3B5D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2B7EF8),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next INR Check',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_nextCheckDays days',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3B5D),
                                    ),
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

                // Analyze INR Change Button (only for High Risk)
                if (_riskLevel == 'High Risk') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                InrChangeScreen(currentInr: _enteredInr),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Analyze INR Change',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],

              // INR Trend Card
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
                        const Text(
                          'INR Trend',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(
                            Icons.date_range,
                            size: 18,
                            color: Color(0xFF2B7EF8),
                          ),
                          label: const Text(
                            'Select Range',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2B7EF8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingTrend)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2B7EF8),
                            ),
                          ),
                        ),
                      )
                    else if (_inrTrendData.isEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insert_chart_outlined,
                                size: 48,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Insufficient Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No INR records found for this period',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 1,
                              verticalInterval: _inrTrendData.length > 10
                                  ? (_inrTrendData.length / 10)
                                        .ceil()
                                        .toDouble()
                                  : 1,
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
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: _inrTrendData.length > 5
                                      ? (_inrTrendData.length / 3)
                                            .ceil()
                                            .toDouble()
                                      : 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= _inrTrendData.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = _inrTrendData[index]['date'];
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        DateFormat(
                                          'MM/dd',
                                        ).format(DateTime.parse(date)),
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (_inrTrendData.length - 1).toDouble(),
                            minY: 0,
                            maxY: 5,
                            lineBarsData: [
                              // INR Values Line
                              LineChartBarData(
                                spots: _getInrDataFromApi(),
                                isCurved: true,
                                color: const Color(0xFF2B7EF8),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: const Color(0xFF2B7EF8),
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(
                                    0xFF2B7EF8,
                                  ).withOpacity(0.1),
                                ),
                              ),
                              // Target Range Min Line
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, _targetMin),
                                  FlSpot(
                                    (_inrTrendData.length - 1).toDouble(),
                                    _targetMin,
                                  ),
                                ],
                                isCurved: false,
                                color: const Color(0xFF10B981),
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                dashArray: [5, 5],
                              ),
                              // Target Range Max Line
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, _targetMax),
                                  FlSpot(
                                    (_inrTrendData.length - 1).toDouble(),
                                    _targetMax,
                                  ),
                                ],
                                isCurved: false,
                                color: const Color(0xFF10B981),
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                dashArray: [5, 5],
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    if (spot.barIndex == 0) {
                                      final index = spot.x.toInt();
                                      if (index >= 0 &&
                                          index < _inrTrendData.length) {
                                        final date =
                                            _inrTrendData[index]['date'];
                                        return LineTooltipItem(
                                          '${DateFormat('MMM d').format(DateTime.parse(date))}\nINR: ${spot.y.toStringAsFixed(1)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                    }
                                    return null;
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_isLoadingTrend && _inrTrendData.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            color: const Color(0xFF2B7EF8),
                            label: 'INR Values',
                          ),
                          const SizedBox(width: 24),
                          _buildLegendItem(
                            color: const Color(0xFF10B981),
                            label: 'Target Range',
                            isDashed: true,
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isDashed = false,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color, width: 2) : null,
          ),
          child: isDashed
              ? CustomPaint(painter: DashedLinePainter(color: color))
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
