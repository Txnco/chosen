import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/notification_preferences.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/main.dart';
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

  // Helper method to parse time string "HH:MM" to hour and minute
  static Map<String, int> _parseTime(String? timeString) {
    if (timeString == null || !timeString.contains(':')) {
      return {'hour': 20, 'minute': 0}; // Default to 20:00
    }

    try {
      final parts = timeString.split(':');
      return {
        'hour': int.parse(parts[0]),
        'minute': int.parse(parts[1]),
      };
    } catch (e) {
      print('Error parsing time string: $timeString');
      return {'hour': 20, 'minute': 0};
    }
  }

  // Helper method to convert day string to weekday int
  static int _parseDayOfWeek(String? dayString) {
    if (dayString == null) return DateTime.monday;

    const dayMap = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    return dayMap[dayString.toLowerCase()] ?? DateTime.monday;
  }

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
    // Handle notification tap - navigate to specific screens based on payload
    final payload = response.payload;
    print('Notification tapped: $payload');

    if (payload == null) return;

    // Use the global navigator key to navigate
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('Navigation context not available');
      return;
    }

    // Navigate to appropriate screen based on notification type
    switch (payload) {
      case 'daily_planning':
        // Navigate to dashboard where daily planning happens
        navigatorKey.currentState?.pushNamed('/dashboard');
        break;
      case 'day_rating':
        // Navigate to day rating screen
        navigatorKey.currentState?.pushNamed('/day-rating');
        break;
      case 'progress_photo':
        // Navigate to progress photos screen
        navigatorKey.currentState?.pushNamed('/progress-photos');
        break;
      case 'weight_tracking':
        // Navigate to weight tracking screen
        navigatorKey.currentState?.pushNamed('/weight-tracking');
        break;
      case 'water_intake':
        // Navigate to water tracking screen
        navigatorKey.currentState?.pushNamed('/water-tracking');
        break;
      case 'birthday':
        // Navigate to dashboard for birthday
        navigatorKey.currentState?.pushNamed('/dashboard');
        break;
      default:
        print('Unknown notification payload: $payload');
    }
  }

  // Schedule daily planning reminder
  static Future<void> scheduleDailyPlanningReminder({
    required bool enabled,
    String? time,
  }) async {
    await _notifications.cancel(dailyPlanningId);

    if (!enabled) return;

    final timeData = _parseTime(time);
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeData['hour']!,
      timeData['minute']!,
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

  // Schedule day rating notification
  static Future<void> scheduleDayRatingReminder({
    required bool enabled,
    String? time,
  }) async {
    await _notifications.cancel(dayRatingId);

    if (!enabled) return;

    final timeData = _parseTime(time);
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeData['hour']!,
      timeData['minute']!,
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
    String? day,
    String? time,
  }) async {
    await _notifications.cancel(weeklyProgressPhotoId);

    if (!enabled) return;

    final dayOfWeek = _parseDayOfWeek(day);
    final timeData = _parseTime(time);
    var scheduledDate = _nextInstanceOfWeekday(dayOfWeek, timeData['hour']!, timeData['minute']!);

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
    String? day,
    String? time,
  }) async {
    await _notifications.cancel(weeklyWeightId);

    if (!enabled) return;

    final dayOfWeek = _parseDayOfWeek(day);
    final timeData = _parseTime(time);
    var scheduledDate = _nextInstanceOfWeekday(dayOfWeek, timeData['hour']!, timeData['minute']!);

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
    String? time,
  }) async {
    await _notifications.cancel(birthdayId);

    if (!enabled || user?.birthdate == null) return;

    final birthdate = user!.birthdate!;
    final now = DateTime.now();
    final timeData = _parseTime(time);

    // Schedule for this year's birthday
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      birthdate.month,
      birthdate.day,
      timeData['hour']!,
      timeData['minute']!,
    );

    // If birthday has passed this year, schedule for next year
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year + 1,
        birthdate.month,
        birthdate.day,
        timeData['hour']!,
        timeData['minute']!,
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
  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
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

  // Reschedule all notifications based on API preferences
  static Future<void> rescheduleAllNotifications(UserModel? user) async {
    // Fetch latest preferences from API
    final apiPrefs = await fetchPreferencesFromApi();

    if (apiPrefs == null) {
      // Fallback to local settings if API fails
      final settings = await getNotificationSettings();
      final prefs = await SharedPreferences.getInstance();
      final waterInterval = prefs.getInt('notification_water_interval') ?? 2;

      await scheduleDailyPlanningReminder(enabled: settings['daily_planning'] ?? false);
      await scheduleDayRatingReminder(enabled: settings['day_rating'] ?? false);
      await scheduleWeeklyProgressPhotoReminder(enabled: settings['progress_photo'] ?? false);
      await scheduleWeeklyWeightReminder(enabled: settings['weight'] ?? false);
      await scheduleWaterReminders(enabled: settings['water'] ?? false, intervalHours: waterInterval);
      await scheduleBirthdayNotification(enabled: settings['birthday'] ?? false, user: user);
      return;
    }

    // Use API preferences
    await scheduleDailyPlanningReminder(
      enabled: apiPrefs.dailyPlanning.enabled,
      time: apiPrefs.dailyPlanning.time,
    );
    await scheduleDayRatingReminder(
      enabled: apiPrefs.dayRating.enabled,
      time: apiPrefs.dayRating.time,
    );
    await scheduleWeeklyProgressPhotoReminder(
      enabled: apiPrefs.progressPhoto.enabled,
      day: apiPrefs.progressPhoto.day,
      time: apiPrefs.progressPhoto.time,
    );
    await scheduleWeeklyWeightReminder(
      enabled: apiPrefs.weightTracking.enabled,
      day: apiPrefs.weightTracking.day,
      time: apiPrefs.weightTracking.time,
    );
    await scheduleWaterReminders(
      enabled: apiPrefs.waterReminders.enabled,
      intervalHours: apiPrefs.waterReminders.intervalHours ?? 2,
    );
    await scheduleBirthdayNotification(
      enabled: apiPrefs.birthday.enabled,
      user: user,
      time: apiPrefs.birthday.time,
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
        day: 'monday',  // Changed from 1
        time: '09:00',
      ),
      weightTracking: NotificationPreference(
        enabled: settings['weight'] ?? false,
        day: 'monday',  // Changed from 1
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
