import 'dart:convert';
import 'package:app/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/user_preferences.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _monthlyData;
  bool _isLoadingMonthly = true;

  //static const String _baseUrl = '$baseURL';

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _fetchMonthlyData();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await UserPreferences.getUserId();
      print('📋 [ReportScreen] userId from prefs: $userId');

      if (userId == null) {
        print('❌ [ReportScreen] userId is null — user not logged in');
        setState(() {
          _error = 'User not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final url = '$baseURL/inr/id/$userId';
      print('🌐 [ReportScreen] Calling: GET $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print('📡 [ReportScreen] Response status: ${response.statusCode}');
      print('📦 [ReportScreen] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ [ReportScreen] Parsed ${data.length} records');
        setState(() {
          _reports = data.map((e) => e as Map<String, dynamic>).toList()
            ..sort((a, b) {
              final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(0);
              final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(0);
              return dateB.compareTo(dateA); // newest first
            });
          _isLoading = false;
        });
        print('✅ [ReportScreen] Reports set in state: ${_reports.length}');
      } else {
        print('❌ [ReportScreen] Bad status: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load reports (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('❌ [ReportScreen] Exception: $e');
      print('🔍 [ReportScreen] Stack: $stack');
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMonthlyData() async {
    if (mounted) setState(() => _isLoadingMonthly = true);
    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoadingMonthly = false);
        return;
      }
      final response = await http
          .get(Uri.parse('$baseURL/health-factor/monthly-analysis/$userId'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        setState(() {
          _monthlyData = decoded;
          _isLoadingMonthly = false;
        });
      } else {
        setState(() => _isLoadingMonthly = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMonthly = false);
    }
  }

  String get _spo2Label {
    final spo2 = _monthlyData?['spo2'];
    if (spo2 == null) return 'okay';
    return ((spo2 as Map<String, dynamic>)['label'] as String?)
            ?.toLowerCase() ??
        'okay';
  }

  String get _hrLabel {
    final hr = _monthlyData?['heartRate'];
    if (hr == null) return 'okay';
    return ((hr as Map<String, dynamic>)['label'] as String?)?.toLowerCase() ??
        'okay';
  }

  Color _labelBgColor(String label) {
    switch (label) {
      case 'warning':
        return const Color(0xFFFEF3C7);
      case 'bad':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  Color _labelAccentColor(String label) {
    switch (label) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'bad':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _labelIcon(String label) {
    switch (label) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'bad':
        return Icons.cancel_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _labelBadge(String label) {
    switch (label) {
      case 'warning':
        return 'Warning';
      case 'bad':
        return 'Bad';
      default:
        return 'Okay';
    }
  }

  String _spo2Description(String label) {
    switch (label) {
      case 'warning':
        return 'Your SpO₂ levels are slightly below the optimal range. Keep monitoring and consider reducing exercise intensity if you feel breathless or lightheaded.';
      case 'bad':
        return 'Your SpO₂ levels are below the safe threshold. Please stop exercising and consult your healthcare provider immediately before resuming any physical activity.';
      default:
        return 'Great news! Your oxygen saturation levels are consistently within the healthy range (≥95%). Keep up your current exercise routine — your body is responding well.';
    }
  }

  String _hrDescription(String label) {
    switch (label) {
      case 'warning':
        return 'Your heart rate is showing slight irregularities this month. Consider lowering your exercise intensity and pay close attention to how your body responds during activity.';
      case 'bad':
        return 'Your heart rate readings are outside the safe range. Please stop exercising and contact your healthcare provider before continuing any physical activity.';
      default:
        return 'Your heart rate is well within the optimal range (60–100 bpm). Your cardiovascular fitness is improving steadily — keep maintaining your regular exercise schedule.';
    }
  }

  Widget _buildAnalysisCard({
    required String title,
    required String label,
    required String description,
  }) {
    final bg = _labelBgColor(label);
    final accent = _labelAccentColor(label);
    final icon = _labelIcon(label);
    final badge = _labelBadge(label);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent, width: 2),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
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
    );
  }

  Color _actionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'MAINTAIN':
        return const Color(0xFF10B981);
      case 'INCREASE':
        return const Color(0xFF2B7EF8);
      case 'DECREASE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.toUpperCase()) {
      case 'MAINTAIN':
        return Icons.check_circle_outline;
      case 'INCREASE':
        return Icons.arrow_upward_rounded;
      case 'DECREASE':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Color _inrColor(double? inr) {
    if (inr == null) return const Color(0xFF6B7280);
    if (inr < 2.0) return const Color(0xFF2B7EF8); // too low
    if (inr > 3.5) return const Color(0xFFEF4444); // too high
    return const Color(0xFF10B981); // in range
  }

  String _inrLabel(double? inr) {
    if (inr == null) return 'Unknown';
    if (inr < 2.0) return 'Below Range';
    if (inr > 3.5) return 'Above Range';
    return 'In Range';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'INR Reports',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2B7EF8)),
            onPressed: _fetchReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B7EF8)),
            )
          : _error != null
          ? _buildErrorState()
          : _reports.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_fetchReports(), _fetchMonthlyData()]);
              },
              color: const Color(0xFF2B7EF8),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummaryHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildReportCard(_reports[index], index),
                        childCount: _reports.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
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
                            const SizedBox(height: 8),
                            const Text(
                              'Based on your current progress trends:',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_isLoadingMonthly)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2B7EF8),
                                  ),
                                ),
                              )
                            else ...[
                              _buildAnalysisCard(
                                title: 'Expected SpO₂',
                                label: _spo2Label,
                                description: _spo2Description(_spo2Label),
                              ),
                              const SizedBox(height: 16),
                              _buildAnalysisCard(
                                title: 'Expected Heart Rate',
                                label: _hrLabel,
                                description: _hrDescription(_hrLabel),
                              ),
                            ],
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

  Widget _buildSummaryHeader() {
    final latestInr = (_reports.first['inr'] as num?)?.toDouble();
    final approved = _reports.where((r) => r['isApproved'] == true).length;
    final pending = _reports.where((r) => r['isApproved'] == false).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B7EF8), Color(0xFF1E6FE8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_information, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'INR Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'Latest INR',
                  value: latestInr != null
                      ? latestInr.toStringAsFixed(1)
                      : '--',
                  sub: _inrLabel(latestInr),
                  valueColor: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _summaryTile(
                  label: 'Approved',
                  value: '$approved',
                  sub: 'records',
                  valueColor: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _summaryTile(
                  label: 'Pending',
                  value: '$pending',
                  sub: 'review',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final inr = (report['inr'] as num?)?.toDouble();
    final dose = (report['dose'] as num?)?.toDouble();
    final action = report['action'] as String?;
    final isApproved = report['isApproved'] == true;
    final date = report['date'] as String?;
    final risk = report['risk'] as String?;
    final nextCheck = report['nextcheck'] as String?;

    final cardColor = _actionColor(action);
    final cardIcon = _actionIcon(action);
    final inrColor = _inrColor(inr);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header with date + status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cardIcon, color: cardColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3B5D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record #${report['id'] ?? index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                // Approval badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isApproved
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle
                            : Icons.pending_outlined,
                        size: 13,
                        color: isApproved
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isApproved
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // INR + Dose row
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        label: 'INR Value',
                        value: inr != null ? inr.toStringAsFixed(1) : '--',
                        sub: _inrLabel(inr),
                        color: inrColor,
                        bgColor: inrColor.withOpacity(0.08),
                        icon: Icons.bloodtype_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricBox(
                        label: 'Dose',
                        value: dose != null
                            ? '${dose.toStringAsFixed(2)} mg'
                            : '--',
                        sub: 'Warfarin',
                        color: const Color(0xFF2B7EF8),
                        bgColor: const Color(0xFFDEEBFF),
                        icon: Icons.medication_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(cardIcon, color: cardColor, size: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended Action',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action ?? 'No action specified',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Risk / Next check (only if present)
                if (risk != null || nextCheck != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (risk != null)
                        Expanded(
                          child: _infoChip(
                            icon: Icons.warning_amber_rounded,
                            label: 'Risk',
                            value: risk,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      if (risk != null && nextCheck != null)
                        const SizedBox(width: 10),
                      if (nextCheck != null)
                        Expanded(
                          child: _infoChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Next Check',
                            value: _formatDate(nextCheck),
                            color: const Color(0xFF2B7EF8),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFEF4444),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7EF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              color: Color(0xFF9CA3AF),
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'No INR reports yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3B5D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your INR records will appear here once\nyour doctor submits a report.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B7EF8),
                side: const BorderSide(color: Color(0xFF2B7EF8)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
