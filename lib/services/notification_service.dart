import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone (if not already done)
    try {
      tz.initializeTimeZones();
      // Set local timezone
      tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    } catch (e) {
      print('Timezone already initialized or error: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // Show notifications while app is in foreground on iOS
      notificationCategories: [],
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('Notification plugin initialized: $initialized');

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request permissions for iOS
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final iosPermission = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS notification permission: $iosPermission');
    }

    // Request permissions for Android 13+
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final androidPermission = await androidImpl
          .requestNotificationsPermission();
      print('Android notification permission: $androidPermission');

      // Request exact alarm permission for Android 12+
      final exactAlarmPermission = await androidImpl
          .requestExactAlarmsPermission();
      print('Android exact alarm permission: $exactAlarmPermission');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      // Test notification channel
      const testChannel = AndroidNotificationChannel(
        'warfarin_test',
        'Test Notifications',
        description: 'Test notifications for debugging',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Warfarin reminders channel
      const remindersChannel = AndroidNotificationChannel(
        'warfarin_reminders',
        'Medication Reminders',
        description: 'Reminders for warfarin medication schedule',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImpl.createNotificationChannel(testChannel);
      await androidImpl.createNotificationChannel(remindersChannel);

      print('✅ Notification channels created');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - app will open automatically
    print('Notification tapped: ${response.payload}');
  }

  // Check if notifications are enabled
  Future<bool> checkPermissions() async {
    if (await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .areNotificationsEnabled();
      print('Android notifications enabled: $granted');
      return granted ?? false;
    }
    // For iOS, assume granted if we got here
    return true;
  }

  // Request permissions explicitly
  Future<bool> requestPermissions() async {
    print('Requesting notification permissions...');

    // For Android 13+
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      print('Android permission granted: $granted');
      if (granted == true) return true;
    }

    // For iOS
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS permission granted: $granted');
      return granted ?? false;
    }

    return false;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleWarfarinReminders(String warfarinTime) async {
    try {
      // Cancel existing notifications
      await cancelAllNotifications();

      // Parse warfarin time (format: "HH:mm")
      final parts = warfarinTime.split(':');
      if (parts.length < 2) return;

      final warfarinHour = int.parse(parts[0]);
      final warfarinMinute = int.parse(parts[1]);

      // Calculate times
      final now = DateTime.now();

      // Stop Food times (2 hours before warfarin)
      final stopFoodHour = warfarinHour - 2;
      _scheduleStopFoodNotifications(now, stopFoodHour, warfarinMinute);

      // Take Warfarin times
      _scheduleTakeWarfarinNotifications(now, warfarinHour, warfarinMinute);

      // Start Food times (2 hours after warfarin)
      final startFoodHour = warfarinHour + 2;
      _scheduleStartFoodNotifications(now, startFoodHour, warfarinMinute);

      print('All notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  void _scheduleStopFoodNotifications(
    DateTime now,
    int targetHour,
    int targetMinute,
  ) {
    // Notification 1: 30 minutes before (e.g., 9:30 for 10:00 target)
    _scheduleNotification(
      id: 1,
      title: '🍽️ Stop Food Reminder',
      body: 'Time to stop eating! You should stop food in 30 minutes.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 30),
    );

    // Notification 2: 10 minutes before (e.g., 9:50 for 10:00 target)
    _scheduleNotification(
      id: 2,
      title: '🍽️ Stop Food Reminder',
      body:
          'Final reminder! Stop eating in 10 minutes to prepare for warfarin.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 10),
    );

    // Notification 3: At the exact time (e.g., 10:00)
    _scheduleNotification(
      id: 3,
      title: '🍽️ Stop Food Now',
      body: 'Please stop eating now. Time to prepare for your warfarin dose.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute),
    );
  }

  void _scheduleTakeWarfarinNotifications(
    DateTime now,
    int targetHour,
    int targetMinute,
  ) {
    // Notification 1: 30 minutes before
    _scheduleNotification(
      id: 4,
      title: '💊 Warfarin Reminder',
      body: 'Your warfarin dose is due in 30 minutes. Get ready!',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 30),
    );

    // Notification 2: 10 minutes before
    _scheduleNotification(
      id: 5,
      title: '💊 Warfarin Reminder',
      body: 'Take your warfarin in 10 minutes. Don\'t forget!',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 10),
    );

    // Notification 3: At the exact time
    _scheduleNotification(
      id: 6,
      title: '💊 Take Your Warfarin Now',
      body: 'It\'s time to take your warfarin dose. Please take it now.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute),
    );
  }

  void _scheduleStartFoodNotifications(
    DateTime now,
    int targetHour,
    int targetMinute,
  ) {
    // Notification 1: 30 minutes before
    _scheduleNotification(
      id: 7,
      title: '🍴 Start Food Soon',
      body: 'You can start eating in 30 minutes after taking warfarin.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 30),
    );

    // Notification 2: 10 minutes before
    _scheduleNotification(
      id: 8,
      title: '🍴 Start Food Soon',
      body: 'Almost time! You can start eating in 10 minutes.',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute - 10),
    );

    // Notification 3: At the exact time
    _scheduleNotification(
      id: 9,
      title: '🍴 Start Food Now',
      body: 'You can start eating now. Enjoy your meal!',
      scheduledDate: _getScheduledTime(now, targetHour, targetMinute),
    );
  }

  DateTime _getScheduledTime(DateTime now, int hour, int minute) {
    // Handle negative minutes (wrap to previous hour)
    int adjustedHour = hour;
    int adjustedMinute = minute;

    while (adjustedMinute < 0) {
      adjustedMinute += 60;
      adjustedHour -= 1;
    }

    // Handle minute overflow (wrap to next hour)
    while (adjustedMinute >= 60) {
      adjustedMinute -= 60;
      adjustedHour += 1;
    }

    // Handle hour overflow/underflow
    if (adjustedHour < 0) adjustedHour += 24;
    if (adjustedHour >= 24) adjustedHour -= 24;

    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      adjustedHour,
      adjustedMinute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'warfarin_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders for warfarin medication schedule',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        ticker: 'Medication reminder',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Scheduled notification $id: $title at $scheduledDate');
    } catch (e) {
      print('Error scheduling notification $id: $e');
    }
  }

  // Send an immediate test notification
  Future<void> sendTestNotification() async {
    try {
      print('Attempting to send test notification...');

      // Check and request permissions
      if (Platform.isAndroid) {
        final androidImpl = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          final granted = await androidImpl.areNotificationsEnabled();
          print('Android notifications enabled: $granted');
          if (granted != true) {
            final requested = await androidImpl
                .requestNotificationsPermission();
            print('Android permission requested: $requested');
            if (requested != true) {
              print('❌ Permission denied.');
              return;
            }
          }
        }
      } else if (Platform.isIOS) {
        final iosImpl = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImpl != null) {
          final granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('iOS permission: $granted');
          if (granted != true) {
            print('❌ iOS permission denied.');
            return;
          }
        }
      }

      final testMessages = [
        {
          'title': '🔔 Test Notification',
          'body':
              'This is a test notification. Your notifications are working!',
        },
        {
          'title': '🍽️ Meal Reminder Test',
          'body':
              'Testing meal reminder notifications. All systems operational!',
        },
        {
          'title': '💊 Warfarin Alert Test',
          'body': 'Your notification system is configured correctly!',
        },
        {
          'title': '✅ Notification Test',
          'body':
              'Success! You will receive timely reminders for your medication.',
        },
        {
          'title': '🩺 System Check',
          'body': 'Notification test completed successfully. You are all set!',
        },
      ];

      // Select a random message
      final random =
          DateTime.now().millisecondsSinceEpoch % testMessages.length;
      final message = testMessages[random];

      print('Selected test message: ${message['title']}');

      // Use a unique ID each time to avoid conflicts
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      const androidDetails = AndroidNotificationDetails(
        'warfarin_test',
        'Test Notifications',
        channelDescription: 'Test notifications for debugging',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        ongoing: false,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        ticker: 'Test notification',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use .show() for IMMEDIATE notification - works in foreground on both platforms
      await _notifications.show(
        notificationId,
        message['title']!,
        message['body']!,
        details,
        payload: 'test_notification',
      );

      print('✅ Test notification sent with id: $notificationId');
      print('Title: ${message['title']}');

      // Check active notifications after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      final activeNotifications = await _notifications.getActiveNotifications();
      print('Active notifications after send: ${activeNotifications.length}');
      for (var n in activeNotifications) {
        print('  - ID: ${n.id}, Title: ${n.title}');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending test notification: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
