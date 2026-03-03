import 'package:flutter/material.dart';
import 'package:app/screens/home/home_screen.dart';
import 'package:app/screens/dose_inr/dose_inr_screen.dart';
import 'package:app/screens/insights/insights_screen.dart';
import 'package:app/screens/report/report_screen.dart';
import 'package:app/screens/recovery/recovery_screen.dart';
import 'package:app/services/user_preferences.dart';
import 'package:app/services/daily_action_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _dailyActionService = DailyActionService();

  final List<Widget> _pages = [
    const HomeScreen(),
    const DoseInrScreen(),
    const InsightsScreen(),
    const ReportScreen(),
    const RecoveryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndPerformDailyAction();
  }

  Future<void> _checkAndPerformDailyAction() async {
    try {
      final needsDailyAction = await UserPreferences.isDailyActionNeeded();

      if (needsDailyAction) {
        final userId = await UserPreferences.getUserId();
        if (userId != null) {
          print('Dashboard: Daily action needed - calling endpoint');
          await _dailyActionService.performDailyAction(userId);

          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await UserPreferences.saveLastDailyActionDate(today);
          print('Dashboard: Daily action completed and date saved: $today');
        }
      } else {
        print('Dashboard: Daily action already performed today');
      }
    } catch (e) {
      print('Dashboard: Error checking daily action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0),
                _buildNavItem(Icons.show_chart, 'Dose & INR', 1),
                _buildNavItem(Icons.trending_up, 'Insights', 2),
                _buildNavItem(Icons.description_outlined, 'Report', 3),
                _buildNavItem(Icons.favorite_border, 'Recovery', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF2B7EF8)
                : const Color(0xFF9CA3AF),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? const Color(0xFF2B7EF8)
                  : const Color(0xFF9CA3AF),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
