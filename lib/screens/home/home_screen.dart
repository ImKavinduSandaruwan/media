import 'package:flutter/material.dart';
import 'package:app/services/daily_actions_service.dart';
import 'package:app/services/user_preferences.dart';
import 'package:app/services/notification_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dailyActionsService = DailyActionsService();
  final _notificationService = NotificationService();
  bool _isStopFoodCompleted = false;
  bool _isTakeWarfarinCompleted = false;
  bool _isConfirmDoseCompleted = false;
  bool _isStartFoodCompleted = false;
  bool _isLoading = false;
  String _warfarinTime = '19:00';
  String _stopFoodTime = '17:00';
  String _startFoodTime = '21:00';

  @override
  void initState() {
    super.initState();
    _loadWarfarinTime();
    _loadActionStates();
  }

  Future<void> _loadWarfarinTime() async {
    try {
      final savedTime = await UserPreferences.getWarfarinDoseTime();
      if (savedTime != null) {
        // Parse the time (format: "HH:mm:ss")
        final parts = savedTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);

          // Set warfarin time
          _warfarinTime = '${parts[0]}:${parts[1]}';

          // Calculate stop food time (2 hours before)
          final stopFoodHour = hour - 2;
          _stopFoodTime =
              '${stopFoodHour.toString().padLeft(2, '0')}:${parts[1]}';

          // Calculate start food time (2 hours after)
          final startFoodHour = hour + 2;
          _startFoodTime =
              '${startFoodHour.toString().padLeft(2, '0')}:${parts[1]}';

          setState(() {});

          // Schedule notifications based on warfarin time
          await _notificationService.scheduleWarfarinReminders(_warfarinTime);
        }
      }
    } catch (e) {
      print('Error loading warfarin time: $e');
    }
  }

  Future<void> _loadActionStates() async {
    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        print('No user ID found');
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await _dailyActionsService.getDailyActions(
        patientId: userId,
        date: today,
      );

      setState(() {
        _isStopFoodCompleted = response.stopFood;
        _isTakeWarfarinCompleted = response.takeWarfarin;
        _isConfirmDoseCompleted = response.confirmDoseTake;
        _isStartFoodCompleted = response.startFood;
      });
    } catch (e) {
      print('Error loading action states: $e');
    }
  }

  Future<void> _handleActionToggle(
    ActionType actionType,
    bool currentState,
  ) async {
    // Only allow checking, not unchecking
    if (currentState) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        _showMessage('User not logged in');
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final success = await _dailyActionsService.updateAction(
        patientId: userId,
        date: today,
        actionType: actionType,
      );

      if (success) {
        // Reload action states from backend
        await _loadActionStates();
        _showMessage('Action completed!');
      } else {
        _showMessage('Failed to update action');
      }
    } catch (e) {
      print('Error toggling action: $e');
      _showMessage('An error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Computed adherence based on today's completed actions
  double get _complianceRate {
    final completed = [
      _isStopFoodCompleted,
      _isTakeWarfarinCompleted,
      _isConfirmDoseCompleted,
      _isStartFoodCompleted,
    ].where((v) => v).length;
    return completed / 4.0;
  }

  String get _adherenceLabel {
    final pct = _complianceRate;
    if (pct == 1.0) return 'Excellent';
    if (pct >= 0.75) return 'Good';
    if (pct >= 0.5) return 'Fair';
    if (pct > 0) return 'Started';
    return 'Pending';
  }

  Color get _adherenceLabelColor {
    final pct = _complianceRate;
    if (pct == 1.0) return const Color(0xFF059669);
    if (pct >= 0.75) return const Color(0xFF2B7EF8);
    if (pct >= 0.5) return const Color(0xFFF59E0B);
    if (pct > 0) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  Color get _adherenceLabelBgColor {
    final pct = _complianceRate;
    if (pct == 1.0) return const Color(0xFFD1FAE5);
    if (pct >= 0.75) return const Color(0xFFDBEAFE);
    if (pct >= 0.5) return const Color(0xFFFEF3C7);
    if (pct > 0) return const Color(0xFFFEF3C7);
    return const Color(0xFFF3F4F6);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome,',
              style: TextStyle(
                color: Color(0xFF1A3B5D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'User\'s Health Dashboard',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF6B7280),
              size: 26,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 26),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await UserPreferences.clearUserData();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2B7EF8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () async {
                // Check permissions first
                final hasPermission = await _notificationService
                    .checkPermissions();

                if (!hasPermission) {
                  // Request permissions
                  final granted = await _notificationService
                      .requestPermissions();

                  if (!granted) {
                    _showMessage(
                      '⚠️ Notification permission denied. Please enable notifications in Settings.',
                    );
                    return;
                  }
                }

                // Send test notification
                await _notificationService.sendTestNotification();
                _showMessage(
                  '✅ Test notification sent! Check your notification tray.',
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActionStates,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Daily Adherence Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Adherence',
                            style: TextStyle(
                              fontSize: 18,
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
                              color: _adherenceLabelBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _adherenceLabel,
                              style: TextStyle(
                                color: _adherenceLabelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Compliance Rate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '${(_complianceRate * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
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
                          value: _complianceRate,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _adherenceLabelColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Actions
                const Text(
                  'Today\'s Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5D),
                  ),
                ),

                const SizedBox(height: 12),

                // Stop Food Action
                _buildActionCard(
                  icon: Icons.remove,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF10B981),
                  title: 'Stop Food',
                  time: _stopFoodTime,
                  borderColor: const Color(0xFF10B981),
                  isCompleted: _isStopFoodCompleted,
                  onTap: () => _handleActionToggle(
                    ActionType.STOP_FOOD,
                    _isStopFoodCompleted,
                  ),
                ),

                const SizedBox(height: 12),

                // Take Warfarin Action
                _buildActionCard(
                  icon: Icons.medication_outlined,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF2B7EF8),
                  title: 'Take Warfarin',
                  time: _warfarinTime,
                  borderColor: const Color(0xFF2B7EF8),
                  isCompleted: _isTakeWarfarinCompleted,
                  onTap: () => _handleActionToggle(
                    ActionType.TAKE_WARFARIN,
                    _isTakeWarfarinCompleted,
                  ),
                ),

                const SizedBox(height: 12),

                // Confirm Dose Taken
                _buildSimpleActionCard(
                  icon: Icons.check,
                  title: 'Confirm Dose Taken',
                  isCompleted: _isConfirmDoseCompleted,
                  onTap: () => _handleActionToggle(
                    ActionType.CONFIRM_DOSE,
                    _isConfirmDoseCompleted,
                  ),
                ),

                const SizedBox(height: 12),

                // Start Food
                _buildSimpleActionCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Start Food',
                  subtitle: _startFoodTime,
                  isCompleted: _isStartFoodCompleted,
                  onTap: () => _handleActionToggle(
                    ActionType.START_FOOD,
                    _isStartFoodCompleted,
                  ),
                ),

                const SizedBox(height: 24),

                // Daily Trackers
                const Text(
                  'Daily Trackers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5D),
                  ),
                ),

                const SizedBox(height: 12),

                // Extra Dose Taken
                _buildTrackerCard(
                  context: context,
                  icon: Icons.medication_outlined,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Extra Dose Taken',
                  subtitle: 'Additional warfarin dose',
                  buttonText: 'Record',
                  route: '/extra-dose',
                ),

                const SizedBox(height: 12),

                // Vitamin K Intake
                _buildTrackerCard(
                  context: context,
                  icon: Icons.restaurant_outlined,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF10B981),
                  title: 'Vitamin K Intake',
                  subtitle: 'Green leafy vegetables',
                  buttonText: 'Track',
                  route: '/vitamin-k',
                ),

                const SizedBox(height: 12),

                // Extra Medication
                _buildTrackerCard(
                  context: context,
                  icon: Icons.medication_liquid_outlined,
                  iconBgColor: const Color(0xFFE9D5FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'Extra Medication',
                  subtitle: 'Other medicines today',
                  buttonText: 'Add',
                  route: '/extra-medication',
                ),

                const SizedBox(height: 12),

                // Symptoms
                _buildTrackerCard(
                  context: context,
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Symptoms',
                  subtitle: 'Report any symptoms',
                  buttonText: 'Report',
                  route: '/symptoms',
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String time,
    required Color borderColor,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3B5D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF10B981) : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7280), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3B5D),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF10B981) : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required String route,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3B5D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B7EF8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
