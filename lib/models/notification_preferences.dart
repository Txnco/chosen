class NotificationPreference {
  final bool enabled;
  final String? time;
  final int? day;
  final int? intervalHours;
  final String? birthdayDate;

  NotificationPreference({
    required this.enabled,
    this.time,
    this.day,
    this.intervalHours,
    this.birthdayDate,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      enabled: json['enabled'] ?? false,
      time: json['time'],
      day: json['day'] is String ? _parseDayString(json['day']) : json['day'],
      intervalHours: json['interval_hours'],
      birthdayDate: json['birthday_date'],
    );
  }

  static int? _parseDayString(String? day) {
    if (day == null) return null;
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final index = days.indexOf(day.toLowerCase());
    return index >= 0 ? index + 1 : 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'enabled': enabled,
    };
    if (time != null) data['time'] = time;
    if (day != null) data['day'] = day;
    if (intervalHours != null) data['interval_hours'] = intervalHours;
    return data;
  }
}

class NotificationPreferences {
  final NotificationPreference dailyPlanning;
  final NotificationPreference dayRating;
  final NotificationPreference progressPhoto;
  final NotificationPreference weightTracking;
  final NotificationPreference waterReminders;
  final NotificationPreference birthday;

  NotificationPreferences({
    required this.dailyPlanning,
    required this.dayRating,
    required this.progressPhoto,
    required this.weightTracking,
    required this.waterReminders,
    required this.birthday,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'] ?? json;
    
    return NotificationPreferences(
      dailyPlanning: NotificationPreference.fromJson(
        notifications['daily_planning'] ?? {'enabled': true, 'time': '20:00'},
      ),
      dayRating: NotificationPreference.fromJson(
        notifications['day_rating'] ?? {'enabled': true, 'time': '20:00'},
      ),
      progressPhoto: NotificationPreference.fromJson(
        notifications['progress_photo'] ?? {'enabled': true, 'day': 1, 'time': '09:00'},
      ),
      weightTracking: NotificationPreference.fromJson(
        notifications['weight_tracking'] ?? {'enabled': true, 'day': 1, 'time': '08:00'},
      ),
      waterReminders: NotificationPreference.fromJson(
        notifications['water_reminders'] ?? {'enabled': true, 'interval_hours': 2},
      ),
      birthday: NotificationPreference.fromJson(
        notifications['birthday'] ?? {'enabled': true, 'time': '09:00'},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_planning': dailyPlanning.toJson(),
      'day_rating': dayRating.toJson(),
      'progress_photo': progressPhoto.toJson(),
      'weight_tracking': weightTracking.toJson(),
      'water_reminders': waterReminders.toJson(),
      'birthday': birthday.toJson(),
    };
  }

  factory NotificationPreferences.defaults() {
    return NotificationPreferences(
      dailyPlanning: NotificationPreference(enabled: true, time: '20:00'),
      dayRating: NotificationPreference(enabled: true, time: '20:00'),
      progressPhoto: NotificationPreference(enabled: true, day: 1, time: '09:00'),
      weightTracking: NotificationPreference(enabled: true, day: 1, time: '08:00'),
      waterReminders: NotificationPreference(enabled: true, intervalHours: 2),
      birthday: NotificationPreference(enabled: true, time: '09:00'),
    );
  }
}