// DAILY ACTIONS SYSTEM - COMPLETE WORKFLOW
//
// This system manages the 4 daily tasks that users need to complete each day.
//
// THE 4 ACTIONS:
// -------------
// 1. STOP_FOOD - Stop eating before medication (18:00)
// 2. TAKE_WARFARIN - Take the warfarin medication (19:00)
// 3. CONFIRM_DOSE - Confirm the dose was taken
// 4. START_FOOD - Can start eating again (20:00)
//
// WORKFLOW:
// --------
// Day 1 - Morning:
// 1. User logs in for the first time today
// 2. System calls: GET http://10.198.89.223:8080/daily-action/{userId}/{date}
//    - This initializes the day's actions on the backend
//    - Called ONCE per day (tracked via lastDailyActionDate in SharedPreferences)
// 3. User sees home screen with 4 unchecked actions
//
// Day 1 - Throughout the day:
// 4. User taps on "Stop Food" action
// 5. System calls: PUT http://10.198.89.223:8080/daily-action/update
//    Payload: {
//      "patientId": 4,
//      "date": "2026-03-02",
//      "actionType": "STOP_FOOD"
//    }
// 6. If successful:
//    - Checkbox becomes checked (green with white checkmark)
//    - State saved locally with today's date
//    - User sees "Action completed!" message
// 7. User continues checking other actions throughout the day
// 8. Each checked action remains checked until midnight
//
// Day 2 - Morning:
// 9. User opens app (or logs in)
// 10. System detects new day
// 11. All checkboxes reset to unchecked (date doesn't match saved dates)
// 12. Daily initialization API called again: GET /daily-action/{userId}/{date}
// 13. Process repeats
//
// LOCAL STATE MANAGEMENT:
// ----------------------
// For each action, we store: "action_STOP_FOOD" -> "2026-03-02"
// - When loading: Compare stored date with today
// - If dates match: Show as checked
// - If different or missing: Show as unchecked
//
// This ensures:
// - Actions persist through app restarts on same day
// - Actions automatically reset at midnight
// - No need to query backend for action states
//
// API CALLS:
// ---------
// 1. Daily Initialization (Once per day):
//    GET http://10.198.89.223:8080/daily-action/{userId}/2026-03-02
//    - Called from: login_screen.dart and dashboard_screen.dart
//    - Tracked via: UserPreferences.lastDailyActionDate
//
// 2. Action Update (Each time user checks a box):
//    PUT http://10.198.89.223:8080/daily-action/update
//    Body: {
//      "patientId": 4,
//      "date": "2026-03-02",
//      "actionType": "STOP_FOOD" | "TAKE_WARFARIN" | "CONFIRM_DOSE" | "START_FOOD"
//    }
//    - Called from: home_screen.dart
//    - Tracked via: DailyActionsService (saves date per action type)
//
// KEY FILES:
// ---------
// 1. lib/services/daily_actions_service.dart
//    - updateAction(): Calls PUT endpoint and saves state
//    - isActionCompleted(): Checks if action done today
//    - getAllActionsState(): Gets all 4 action states
//
// 2. lib/screens/home/home_screen.dart
//    - Displays 4 action cards
//    - Handles tap events
//    - Updates UI based on completion state
//
// 3. lib/services/user_preferences.dart
//    - Manages lastDailyActionDate for daily initialization
//
// 4. lib/services/daily_action_service.dart
//    - Handles daily initialization API call
//
// EXAMPLE SCENARIO:
// ----------------
// Monday 9:00 AM:
// - User logs in
// - GET /daily-action/4/2026-03-02 called
// - All 4 actions shown as unchecked
//
// Monday 6:00 PM:
// - User taps "Stop Food"
// - PUT /daily-action/update with actionType: "STOP_FOOD"
// - Stop Food shows as checked
// - Other 3 still unchecked
//
// Monday 7:00 PM:
// - User taps "Take Warfarin"
// - PUT /daily-action/update with actionType: "TAKE_WARFARIN"
// - Take Warfarin shows as checked
// - 2 completed, 2 remaining
//
// Monday 10:00 PM:
// - User closes app with 2 actions completed
//
// Monday 11:30 PM:
// - User reopens app
// - Dashboard checks actions
// - Still shows 2 completed (same day)
//
// Tuesday 8:00 AM:
// - User opens app
// - System detects new day
// - GET /daily-action/4/2026-03-03 called
// - All 4 actions reset to unchecked
// - User can complete today's tasks
