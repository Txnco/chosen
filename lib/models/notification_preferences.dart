class NotificationPreference {
  final bool enabled;
  final String? time;
  final int? day;
  final int? intervalHours;

  NotificationPreference({
    required this.enabled,
    this.time,
    this.day,
    this.intervalHours,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      enabled: json['enabled'] ?? false,
      time: json['time'],
      day: json['day'],
      intervalHours: json['interval_hours'],
    );
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
    return NotificationPreferences(
      dailyPlanning: NotificationPreference.fromJson(
        json['daily_planning'] ?? {'enabled': false, 'time': '20:00'},
      ),
      dayRating: NotificationPreference.fromJson(
        json['day_rating'] ?? {'enabled': false, 'time': '20:00'},
      ),
      progressPhoto: NotificationPreference.fromJson(
        json['progress_photo'] ?? {'enabled': false, 'day': 1, 'time': '09:00'},
      ),
      weightTracking: NotificationPreference.fromJson(
        json['weight_tracking'] ?? {'enabled': false, 'day': 1, 'time': '08:00'},
      ),
      waterReminders: NotificationPreference.fromJson(
        json['water_reminders'] ?? {'enabled': false, 'interval_hours': 2},
      ),
      birthday: NotificationPreference.fromJson(
        json['birthday'] ?? {'enabled': false, 'time': '09:00'},
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

  // Helper method to get defaults
  factory NotificationPreferences.defaults() {
    return NotificationPreferences(
      dailyPlanning: NotificationPreference(enabled: false, time: '20:00'),
      dayRating: NotificationPreference(enabled: false, time: '20:00'),
      progressPhoto: NotificationPreference(enabled: false, day: 1, time: '09:00'),
      weightTracking: NotificationPreference(enabled: false, day: 1, time: '08:00'),
      waterReminders: NotificationPreference(enabled: false, intervalHours: 2),
      birthday: NotificationPreference(enabled: false, time: '09:00'),
    );
  }
}
