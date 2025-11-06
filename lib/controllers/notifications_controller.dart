import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/notification_preferences.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'dart:convert';

class NotificationsController {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int dailyPlanningId = 1;
  static const int dayRatingId = 2;
  static const int weeklyProgressPhotoId = 3;
  static const int weeklyWeightId = 4;
  static const int waterIntakeId = 5;
  static const int birthdayId = 6;

  // Initialize notifications
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions on Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can be extended to navigate to specific screens
    print('Notification tapped: ${response.payload}');
  }

  // Schedule daily planning reminder (1-2 hours before bedtime)
  static Future<void> scheduleDailyPlanningReminder({
    required bool enabled,
    int bedtimeHour = 22,
    int reminderHoursBefore = 2,
  }) async {
    await _notifications.cancel(dailyPlanningId);

    if (!enabled) return;

    final reminderHour = bedtimeHour - reminderHoursBefore;
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderHour,
      0,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      dailyPlanningId,
      'Plan Your Day',
      'Take a moment to plan tomorrow and set your goals!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_planning',
          'Daily Planning',
          channelDescription: 'Reminders to plan your day',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_planning',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_daily_planning', enabled);
  }

  // Schedule day rating notification (evening)
  static Future<void> scheduleDayRatingReminder({
    required bool enabled,
    int hour = 20,
  }) async {
    await _notifications.cancel(dayRatingId);

    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      dayRatingId,
      'Rate Your Day',
      'How was your day? Take a moment to reflect and rate it.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'day_rating',
          'Day Rating',
          channelDescription: 'Reminders to rate your day',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'day_rating',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_day_rating', enabled);
  }

  // Schedule weekly progress photo reminder
  static Future<void> scheduleWeeklyProgressPhotoReminder({
    required bool enabled,
    int dayOfWeek = DateTime.monday,
    int hour = 9,
  }) async {
    await _notifications.cancel(weeklyProgressPhotoId);

    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = _nextInstanceOfWeekday(dayOfWeek, hour);

    await _notifications.zonedSchedule(
      weeklyProgressPhotoId,
      'Weekly Progress Photo',
      'Time for your weekly progress photo! Track your transformation.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'progress_photo',
          'Progress Photos',
          channelDescription: 'Weekly progress photo reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'progress_photo',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_progress_photo', enabled);
  }

  // Schedule weekly weigh-in reminder
  static Future<void> scheduleWeeklyWeightReminder({
    required bool enabled,
    int dayOfWeek = DateTime.monday,
    int hour = 8,
  }) async {
    await _notifications.cancel(weeklyWeightId);

    if (!enabled) return;

    var scheduledDate = _nextInstanceOfWeekday(dayOfWeek, hour);

    await _notifications.zonedSchedule(
      weeklyWeightId,
      'Weekly Weigh-In',
      'Time to record your weight. Consistency is key!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weight_tracking',
          'Weight Tracking',
          channelDescription: 'Weekly weigh-in reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weight_tracking',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_weight', enabled);
  }

  // Schedule water intake reminders
  static Future<void> scheduleWaterReminders({
    required bool enabled,
    int intervalHours = 2,
    int startHour = 8,
    int endHour = 20,
  }) async {
    // Cancel existing water notifications (IDs 100-199 reserved for water)
    for (int i = 100; i < 200; i++) {
      await _notifications.cancel(i);
    }

    if (!enabled) return;

    int notificationId = 100;
    for (int hour = startHour; hour <= endHour; hour += intervalHours) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        notificationId++,
        'Hydration Time',
        'Remember to drink water! Stay hydrated.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_intake',
            'Water Reminders',
            channelDescription: 'Reminders to drink water',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'water_intake',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_water', enabled);
    await prefs.setInt('notification_water_interval', intervalHours);
  }

  // Schedule birthday notification
  static Future<void> scheduleBirthdayNotification({
    required bool enabled,
    required UserModel? user,
  }) async {
    await _notifications.cancel(birthdayId);

    if (!enabled || user?.birthdate == null) return;

    final birthdate = user!.birthdate!;
    final now = DateTime.now();

    // Schedule for this year's birthday
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      birthdate.month,
      birthdate.day,
      9,
      0,
    );

    // If birthday has passed this year, schedule for next year
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year + 1,
        birthdate.month,
        birthdate.day,
        9,
        0,
      );
    }

    await _notifications.zonedSchedule(
      birthdayId,
      'Happy Birthday!',
      '${user.firstName}, wishing you a wonderful birthday! Keep crushing your goals!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday',
          'Birthday',
          channelDescription: 'Birthday notifications',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: 'birthday',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_birthday', enabled);
  }

  // Helper method to get next instance of a specific weekday
  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Get notification status from preferences
  static Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'daily_planning': prefs.getBool('notification_daily_planning') ?? false,
      'day_rating': prefs.getBool('notification_day_rating') ?? false,
      'progress_photo': prefs.getBool('notification_progress_photo') ?? false,
      'weight': prefs.getBool('notification_weight') ?? false,
      'water': prefs.getBool('notification_water') ?? false,
      'birthday': prefs.getBool('notification_birthday') ?? false,
    };
  }

  // Reschedule all notifications based on saved preferences
  static Future<void> rescheduleAllNotifications(UserModel? user) async {
    final settings = await getNotificationSettings();
    final prefs = await SharedPreferences.getInstance();
    final waterInterval = prefs.getInt('notification_water_interval') ?? 2;

    await scheduleDailyPlanningReminder(
      enabled: settings['daily_planning'] ?? false,
    );
    await scheduleDayRatingReminder(
      enabled: settings['day_rating'] ?? false,
    );
    await scheduleWeeklyProgressPhotoReminder(
      enabled: settings['progress_photo'] ?? false,
    );
    await scheduleWeeklyWeightReminder(
      enabled: settings['weight'] ?? false,
    );
    await scheduleWaterReminders(
      enabled: settings['water'] ?? false,
      intervalHours: waterInterval,
    );
    await scheduleBirthdayNotification(
      enabled: settings['birthday'] ?? false,
      user: user,
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_daily_planning', false);
    await prefs.setBool('notification_day_rating', false);
    await prefs.setBool('notification_progress_photo', false);
    await prefs.setBool('notification_weight', false);
    await prefs.setBool('notification_water', false);
    await prefs.setBool('notification_birthday', false);
  }

  // ============== API Integration Methods ==============

  /// Fetch notification preferences from the backend
  static Future<NotificationPreferences?> fetchPreferencesFromApi() async {
    try {
      final response = await ChosenApi.get('/notifications/preferences');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationPreferences.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired or invalid - return null to trigger login
        print('Authentication failed - token may be expired');
        return null;
      } else {
        print('Failed to fetch preferences: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching preferences from API: $e');
      return null;
    }
  }

  /// Update notification preferences on the backend
  static Future<bool> updatePreferencesToApi(NotificationPreferences preferences) async {
    try {
      final response = await ChosenApi.put(
        '/notifications/preferences',
        preferences.toJson(),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        print('Authentication failed - token may be expired');
        return false;
      } else {
        print('Failed to update preferences: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating preferences to API: $e');
      return false;
    }
  }

  /// Reset notification preferences to defaults on the backend
  static Future<bool> resetPreferencesOnApi() async {
    try {
      final response = await ChosenApi.post('/notifications/reset', {});

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        print('Authentication failed - token may be expired');
        return false;
      } else {
        print('Failed to reset preferences: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error resetting preferences on API: $e');
      return false;
    }
  }

  /// Sync local preferences with backend and reschedule notifications
  static Future<void> syncPreferencesWithApi(UserModel? user) async {
    final apiPreferences = await fetchPreferencesFromApi();

    if (apiPreferences != null) {
      // Update local SharedPreferences to match backend
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notification_daily_planning', apiPreferences.dailyPlanning.enabled);
      await prefs.setBool('notification_day_rating', apiPreferences.dayRating.enabled);
      await prefs.setBool('notification_progress_photo', apiPreferences.progressPhoto.enabled);
      await prefs.setBool('notification_weight', apiPreferences.weightTracking.enabled);
      await prefs.setBool('notification_water', apiPreferences.waterReminders.enabled);
      await prefs.setBool('notification_birthday', apiPreferences.birthday.enabled);

      if (apiPreferences.waterReminders.intervalHours != null) {
        await prefs.setInt('notification_water_interval', apiPreferences.waterReminders.intervalHours!);
      }

      // Reschedule all notifications based on synced preferences
      await rescheduleAllNotifications(user);
    }
  }

  /// Convert current local settings to NotificationPreferences object
  static Future<NotificationPreferences> getCurrentPreferences() async {
    final settings = await getNotificationSettings();
    final prefs = await SharedPreferences.getInstance();
    final waterInterval = prefs.getInt('notification_water_interval') ?? 2;

    return NotificationPreferences(
      dailyPlanning: NotificationPreference(
        enabled: settings['daily_planning'] ?? false,
        time: '20:00',
      ),
      dayRating: NotificationPreference(
        enabled: settings['day_rating'] ?? false,
        time: '20:00',
      ),
      progressPhoto: NotificationPreference(
        enabled: settings['progress_photo'] ?? false,
        day: 1,
        time: '09:00',
      ),
      weightTracking: NotificationPreference(
        enabled: settings['weight'] ?? false,
        day: 1,
        time: '08:00',
      ),
      waterReminders: NotificationPreference(
        enabled: settings['water'] ?? false,
        intervalHours: waterInterval,
      ),
      birthday: NotificationPreference(
        enabled: settings['birthday'] ?? false,
        time: '09:00',
      ),
    );
  }
}
