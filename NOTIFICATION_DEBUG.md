# Notification Debugging Guide

## Recent Changes Made

1. **Moved notification initialization to `main.dart`** - Ensures notifications are initialized once at app startup
2. **Added extensive logging** - Every step now prints debug messages
3. **Enhanced Android notification settings** - Added vibration and max importance
4. **Removed duplicate initializations** - Cleaned up register and home screens

## Debugging Steps

### 1. Check Console Logs

When you run the app, you should see:
```
Notification plugin initialized: true
iOS notification permission: true (or null on Android)
Android notification permission: true (or null on iOS)
```

### 2. Test Notification

Click the notification bell icon in the home screen. You should see:
```
Attempting to send test notification...
Selected test message: [title]
Showing notification with ID 999...
✅ Test notification sent successfully: [title]
```

If you see an error, the logs will show:
```
❌ Error sending test notification: [error details]
Stack trace: [trace]
```

### 3. Android Specific Checks

#### Check Device Notification Settings
1. Go to device **Settings** → **Apps** → **Your App**
2. Check **Notifications** are enabled
3. Check **All notification categories** are enabled

#### Check Android Version Specific Permissions
- **Android 13+**: App must request `POST_NOTIFICATIONS` permission
- **Android 12+**: App needs "Alarms & reminders" permission for exact scheduling

#### Verify AndroidManifest.xml has:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

### 4. iOS Specific Checks

#### Check Notification Permissions
1. Go to **Settings** → **Notifications** → **Your App**
2. Ensure "Allow Notifications" is ON
3. Ensure Alert style is set to "Banners" or "Alerts"

### 5. Common Issues

#### Issue: No logs appear
**Solution**: Ensure you're running in debug mode with console visible

#### Issue: "Notification plugin initialized: false"
**Solution**: 
- Check if app has notification permissions
- Reinstall the app
- Clear app data

#### Issue: Test notification logs appear but no notification shows
**Solution**:
- Check device "Do Not Disturb" mode is OFF
- Check device notification settings for the app
- For Android: Check if "Alarms & reminders" permission is granted
- Restart the device

#### Issue: Scheduled notifications don't fire
**Solution**:
- Ensure timezone is correctly initialized
- Check if device time is correct
- Verify scheduled times are in the future
- For Android: Battery optimization might kill background tasks
  - Go to Settings → Battery → Battery Optimization
  - Set app to "Don't optimize"

### 6. Testing Scheduled Notifications

To test scheduled notifications quickly:
1. Set warfarin time to 5-10 minutes from now during registration
2. Wait for the scheduled times
3. Check console for scheduling confirmations like:
   ```
   Scheduled notification 1: 🍽️ Stop Food Reminder at 2026-03-02 13:20:00.000
   Scheduled notification 2: 🍽️ Stop Food Reminder at 2026-03-02 13:40:00.000
   ```

### 7. Force Restart

If nothing works:
1. Stop the app completely
2. Clear app data (or reinstall)
3. Restart device
4. Run the app again
5. Check console logs from the beginning

## Expected Behavior

### Test Notification (Immediate)
- Should appear instantly when clicking bell icon
- Should show one of 5 random test messages
- Should have sound and vibration (if enabled)

### Scheduled Notifications
Each action (Stop Food, Take Warfarin, Start Food) gets 3 notifications:
- 30 minutes before
- 10 minutes before  
- At exact time

Total: 9 notifications per day

## Contact Points in Code

- **Initialization**: `lib/main.dart` (line 14-22)
- **Test Notification**: `lib/services/notification_service.dart` (sendTestNotification method)
- **Schedule Notifications**: `lib/services/notification_service.dart` (scheduleWarfarinReminders method)
- **Android Permissions**: `android/app/src/main/AndroidManifest.xml`
