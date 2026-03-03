// // TESTING HELPER FOR DAILY ACTIONS
// //
// // Use these functions to test the daily actions system
// //

// import 'package:app/services/daily_actions_service.dart';
// import 'package:app/services/user_preferences.dart';

// // Reset all actions (useful for testing)
// Future<void> resetAllActions() async {
//   final service = DailyActionsService();
//   await service.clearAllActions();
//   print('All actions cleared');
// }

// // Check current action states
// Future<void> checkActionStates() async {
//   final service = DailyActionsService();
//   final states = await service.getAllActionsState();

//   print('=== Current Action States ===');
//   print('STOP_FOOD: ${states[ActionType.STOP_FOOD]}');
//   print('TAKE_WARFARIN: ${states[ActionType.TAKE_WARFARIN]}');
//   print('CONFIRM_DOSE: ${states[ActionType.CONFIRM_DOSE]}');
//   print('START_FOOD: ${states[ActionType.START_FOOD]}');
//   print('===========================');
// }

// // Check last daily initialization date
// Future<void> checkLastDailyActionDate() async {
//   final lastDate = await UserPreferences.getLastDailyActionDate();
//   print('Last daily action date: ${lastDate ?? "Never"}');
// }

// // Manual test of action update
// Future<void> testActionUpdate() async {
//   final userId = await UserPreferences.getUserId();
//   if (userId == null) {
//     print('ERROR: No user logged in');
//     return;
//   }

//   final service = DailyActionsService();
//   final success = await service.updateAction(
//     patientId: userId,
//     date: '2026-03-02',
//     actionType: ActionType.STOP_FOOD,
//   );

//   print('Test action update: ${success ? "SUCCESS" : "FAILED"}');
// }

// // HOW TO USE:
// // ----------
// // In your app, you can call these from a debug button:
// //
// // ElevatedButton(
// //   onPressed: () async {
// //     await resetAllActions();
// //     // or
// //     await checkActionStates();
// //   },
// //   child: Text('Debug: Reset Actions'),
// // )
