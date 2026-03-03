// DAILY ACTION SYSTEM - HOW IT WORKS
//
// This system ensures that a specific API endpoint is called exactly once per day
// for each user when they first use the app.
//
// FLOW:
// -----
// 1. User logs in successfully
// 2. System checks if daily action is needed (isDailyActionNeeded())
//    - Compares today's date with the last saved action date
//    - Returns true if different day or no previous action
// 3. If needed, calls: http://10.198.89.223:8080/daily-action/{userId}/{date}
//    - Example: http://10.198.89.223:8080/daily-action/4/2026-03-02
// 4. Saves today's date as lastDailyActionDate
// 5. User proceeds to dashboard
//
// ADDITIONAL PROTECTION:
// ---------------------
// The DashboardScreen also checks on initialization (initState)
// This handles the case where:
// - User opens app while already logged in (didn't go through login screen)
// - App was closed and reopened on a new day
//
// KEY FILES:
// ---------
// 1. lib/services/daily_action_service.dart
//    - Makes the API call to daily-action endpoint
//    - Uses current date in format yyyy-MM-dd
//
// 2. lib/services/user_preferences.dart
//    - saveLastDailyActionDate(): Saves the date when action was performed
//    - getLastDailyActionDate(): Retrieves the last saved date
//    - isDailyActionNeeded(): Checks if today's action is needed
//
// 3. lib/screens/login/login_screen.dart
//    - Calls daily action after successful login
//
// 4. lib/screens/dashboard/dashboard_screen.dart
//    - Calls daily action on app open (if already logged in)
//
// EXAMPLE USAGE:
// -------------
// If you need to manually check or trigger daily action elsewhere:
//
// final needsAction = await UserPreferences.isDailyActionNeeded();
// if (needsAction) {
//   final userId = await UserPreferences.getUserId();
//   if (userId != null) {
//     await DailyActionService().performDailyAction(userId);
//     await UserPreferences.saveLastDailyActionDate(
//       DateFormat('yyyy-MM-dd').format(DateTime.now())
//     );
//   }
// }
//
// TESTING:
// -------
// To test, you can manually clear the saved date:
// - Open app
// - Go to Settings > Apps > Your App > Clear Data
// Or programmatically:
// final prefs = await SharedPreferences.getInstance();
// await prefs.remove('lastDailyActionDate');
