import 'package:flutter/foundation.dart';
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/models/user.dart';

class NotificationProvider extends ChangeNotifier {
  bool _dailyPlanning = false;
  bool _dayRating = false;
  bool _progressPhoto = false;
  bool _weight = false;
  bool _water = false;
  bool _birthday = false;
  int _waterInterval = 2;
  bool _isLoading = false;

  bool get dailyPlanning => _dailyPlanning;
  bool get dayRating => _dayRating;
  bool get progressPhoto => _progressPhoto;
  bool get weight => _weight;
  bool get water => _water;
  bool get birthday => _birthday;
  int get waterInterval => _waterInterval;
  bool get isLoading => _isLoading;

  // Load notification settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final settings = await NotificationsController.getNotificationSettings();
    _dailyPlanning = settings['daily_planning'] ?? false;
    _dayRating = settings['day_rating'] ?? false;
    _progressPhoto = settings['progress_photo'] ?? false;
    _weight = settings['weight'] ?? false;
    _water = settings['water'] ?? false;
    _birthday = settings['birthday'] ?? false;

    _isLoading = false;
    notifyListeners();
  }

  // Toggle daily planning notification
  Future<void> setDailyPlanning(bool value) async {
    _dailyPlanning = value;
    notifyListeners();
    await NotificationsController.scheduleDailyPlanningReminder(enabled: value);
  }

  // Toggle day rating notification
  Future<void> setDayRating(bool value) async {
    _dayRating = value;
    notifyListeners();
    await NotificationsController.scheduleDayRatingReminder(enabled: value);
  }

  // Toggle progress photo notification
  Future<void> setProgressPhoto(bool value) async {
    _progressPhoto = value;
    notifyListeners();
    await NotificationsController.scheduleWeeklyProgressPhotoReminder(enabled: value);
  }

  // Toggle weight tracking notification
  Future<void> setWeight(bool value) async {
    _weight = value;
    notifyListeners();
    await NotificationsController.scheduleWeeklyWeightReminder(enabled: value);
  }

  // Toggle water reminder notification
  Future<void> setWater(bool value, {int? intervalHours}) async {
    _water = value;
    if (intervalHours != null) {
      _waterInterval = intervalHours;
    }
    notifyListeners();
    await NotificationsController.scheduleWaterReminders(
      enabled: value,
      intervalHours: _waterInterval,
    );
  }

  // Set water interval
  Future<void> setWaterInterval(int hours) async {
    _waterInterval = hours;
    notifyListeners();
    if (_water) {
      await NotificationsController.scheduleWaterReminders(
        enabled: true,
        intervalHours: hours,
      );
    }
  }

  // Toggle birthday notification
  Future<void> setBirthday(bool value, UserModel? user) async {
    _birthday = value;
    notifyListeners();
    await NotificationsController.scheduleBirthdayNotification(
      enabled: value,
      user: user,
    );
  }

  // Enable all notifications
  Future<void> enableAll(UserModel? user) async {
    _dailyPlanning = true;
    _dayRating = true;
    _progressPhoto = true;
    _weight = true;
    _water = true;
    _birthday = true;
    notifyListeners();

    await NotificationsController.rescheduleAllNotifications(user);
  }

  // Disable all notifications
  Future<void> disableAll() async {
    _dailyPlanning = false;
    _dayRating = false;
    _progressPhoto = false;
    _weight = false;
    _water = false;
    _birthday = false;
    notifyListeners();

    await NotificationsController.cancelAllNotifications();
  }
}
