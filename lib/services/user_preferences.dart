import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyUserId = 'userId';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'role';
  static const String _keyLastDailyActionDate = 'lastDailyActionDate';
  static const String _keyWarfarinDoseTime = 'warfarinDoseTime';
  static const String _keyRegistrationCompleted = 'registrationCompleted';

  // Save user data
  static Future<void> saveUserData({
    required int userId,
    String? username,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    if (username != null) {
      await prefs.setString(_keyUsername, username);
    }
    if (role != null) {
      await prefs.setString(_keyRole, role);
    }
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Get username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Get role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Clear ALL user data (for logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null;
  }

  // Save last daily action date
  static Future<void> saveLastDailyActionDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDailyActionDate, date);
  }

  // Get last daily action date
  static Future<String?> getLastDailyActionDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastDailyActionDate);
  }

  // Check if daily action is needed for today
  static Future<bool> isDailyActionNeeded() async {
    final lastDate = await getLastDailyActionDate();
    if (lastDate == null) return true;

    final today = DateTime.now();
    final lastActionDate = DateTime.parse(lastDate);

    // Check if the last action was on a different day
    return today.year != lastActionDate.year ||
        today.month != lastActionDate.month ||
        today.day != lastActionDate.day;
  }

  // Save warfarin dose time (format: "HH:mm:ss")
  static Future<void> saveWarfarinDoseTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWarfarinDoseTime, time);
  }

  // Get warfarin dose time
  static Future<String?> getWarfarinDoseTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWarfarinDoseTime);
  }

  // Check if user has completed registration
  static Future<bool> hasCompletedRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRegistrationCompleted) ?? false;
  }

  // Mark registration as completed
  static Future<void> setRegistrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRegistrationCompleted, true);
  }
}
