# Notification Setup Guide

## Overview
The app now includes local notification reminders for warfarin medication schedule with three actions:
1. **Stop Food** - 2 hours before warfarin time
2. **Take Warfarin** - At the scheduled warfarin time
3. **Start Food** - 2 hours after warfarin time

Each action receives **3 reminder notifications**:
- **30 minutes before** the scheduled time
- **10 minutes before** the scheduled time
- **At the exact time**

## How It Works

### Example Schedule
If warfarin time is set to **15:00 (3:00 PM)**:

#### Stop Food Notifications (13:00 - 1:00 PM)
- 12:30 PM: "Time to stop eating! You should stop food in 30 minutes."
- 12:50 PM: "Final reminder! Stop eating in 10 minutes to prepare for warfarin."
- 1:00 PM: "Please stop eating now. Time to prepare for your warfarin dose."

#### Take Warfarin Notifications (15:00 - 3:00 PM)
- 2:30 PM: "Your warfarin dose is due in 30 minutes. Get ready!"
- 2:50 PM: "Take your warfarin in 10 minutes. Don't forget!"
- 3:00 PM: "It's time to take your warfarin dose. Please take it now."

#### Start Food Notifications (17:00 - 5:00 PM)
- 4:30 PM: "You can start eating in 30 minutes after taking warfarin."
- 4:50 PM: "Almost time! You can start eating in 10 minutes."
- 5:00 PM: "You can start eating now. Enjoy your meal!"

## Setup Requirements

### Android
The following permissions have been added to `AndroidManifest.xml`:
- `RECEIVE_BOOT_COMPLETED` - Reschedule notifications after device restart
- `VIBRATE` - Allow notification vibration
- `USE_EXACT_ALARM` - Schedule exact time notifications
- `SCHEDULE_EXACT_ALARM` - Required for Android 12+
- `POST_NOTIFICATIONS` - Required for Android 13+

### iOS
No additional configuration needed. Permissions are requested at runtime.

## When Notifications Are Scheduled

Notifications are automatically scheduled:
1. **During Registration** - When user completes the registration form with warfarin dose time
2. **On Home Screen Load** - When user opens the home screen (ensures notifications stay current)

## Testing Notifications

To test notifications:
1. Complete the registration process with a warfarin dose time
2. Set the warfarin time to be within the next hour for quick testing
3. Wait for the scheduled notification times
4. Notifications will appear even if the app is closed
5. Tapping a notification will open the app

## Code Structure

### NotificationService (`lib/services/notification_service.dart`)
- Manages all notification scheduling
- Handles time calculations
- Configures notification channels and permissions

### Integration Points
- `RegisterScreen` - Schedules notifications after successful registration
- `HomeScreen` - Reschedules notifications when screen loads

## Troubleshooting

### Notifications Not Appearing
1. Check device notification settings - ensure app notifications are enabled
2. For Android 12+, verify "Alarms & reminders" permission is granted
3. Check console logs for scheduling errors
4. Ensure warfarin dose time is saved in SharedPreferences

### Time Zone Issues
The app uses the device's local timezone for all scheduling.

### Rescheduling
Notifications are rescheduled:
- When the user updates their warfarin dose time
- When the home screen loads (refreshes daily schedule)

## Future Enhancements
- Allow users to customize notification messages
- Add notification sound selection
- Allow users to adjust notification timing intervals
- Add notification history tracking
