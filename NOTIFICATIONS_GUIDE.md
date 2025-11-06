# Notifications System Guide

## Overview

The CHOSEN app now includes a comprehensive local notifications system that reminds users to plan and reflect on their day, maintain progress habits, and track health milestones.

## Features

### 1. Daily Planning Reminder
- **Purpose**: Reminds users to plan the next day
- **Default Time**: 2 hours before bedtime (default bedtime: 22:00, so reminder at 20:00)
- **Frequency**: Daily
- **Customizable**: Bedtime hour can be adjusted

### 2. Day Rating Notification
- **Purpose**: Prompts users to rate and reflect on their day
- **Default Time**: 20:00 (8:00 PM)
- **Frequency**: Daily
- **Links to**: `day_rating_tracking_screen.dart`

### 3. Weekly Progress Photo Reminder
- **Purpose**: Reminds users to take progress photos
- **Default Time**: Mondays at 9:00 AM
- **Frequency**: Weekly
- **Links to**: `progress_photos_screen.dart`

### 4. Weekly Weigh-In Reminder
- **Purpose**: Reminds users to record their weight
- **Default Time**: Mondays at 8:00 AM
- **Frequency**: Weekly
- **Links to**: `weight_tracking_screen.dart`

### 5. Water Intake Notifications
- **Purpose**: Periodic reminders to drink water
- **Default Schedule**: Every 2 hours from 8:00 AM to 8:00 PM
- **Frequency**: Configurable (1-4 hour intervals)
- **Links to**: `water_tracking_screen.dart`

### 6. Birthday Notification
- **Purpose**: Sends a personalized birthday greeting
- **Time**: 9:00 AM on user's birthday
- **Frequency**: Yearly
- **Requires**: User birthdate in profile

## Architecture

### File Structure

```
lib/
├── controllers/
│   └── notifications_controller.dart  # Core notification logic
├── providers/
│   └── notification_provider.dart     # State management
├── models/
│   └── user.dart                      # Updated with birthdate field
└── screens/
    └── settings/
        └── settings_screen.dart       # Notification settings UI
```

### Key Components

#### NotificationsController (`notifications_controller.dart`)
- Handles all notification scheduling and cancellation
- Uses `flutter_local_notifications` for local notifications
- Timezone-aware scheduling with `timezone` package
- Persists settings using `shared_preferences`

#### NotificationProvider (`notification_provider.dart`)
- Manages notification state using Provider pattern
- Provides reactive UI updates
- Handles toggle state for each notification type

#### Settings Screen Integration
- Dialog-based notification settings
- Individual toggle switches for each notification type
- Real-time enable/disable functionality
- Settings persist across app restarts

## Usage

### For Users

1. **Open Settings**: Navigate to Settings screen
2. **Access Notifications**: Tap on "Obavještenja" (Notifications)
3. **Configure Notifications**: Toggle individual notification types on/off
4. **Save**: Changes are saved automatically

### For Developers

#### Initialize Notifications

The system is automatically initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsController.initialize();
  // ...
}
```

#### Schedule a Notification

```dart
// Enable daily planning reminder
await NotificationsController.scheduleDailyPlanningReminder(
  enabled: true,
  bedtimeHour: 22,
  reminderHoursBefore: 2,
);
```

#### Check Notification Settings

```dart
final settings = await NotificationsController.getNotificationSettings();
print('Daily planning enabled: ${settings['daily_planning']}');
```

#### Using the Provider

```dart
final notificationProvider = Provider.of<NotificationProvider>(context);

// Toggle a notification
await notificationProvider.setDailyPlanning(true);

// Access state
bool isEnabled = notificationProvider.dailyPlanning;
```

## Testing

### Manual Testing Checklist

#### Basic Functionality
- [ ] Install app and grant notification permissions
- [ ] Open Settings → Notifications
- [ ] Enable each notification type individually
- [ ] Verify settings persist after app restart
- [ ] Disable notifications and verify they stop

#### Notification Types
- [ ] Daily Planning: Set time close to current time, verify notification appears
- [ ] Day Rating: Set time close to current time, verify notification appears
- [ ] Progress Photo: Verify scheduled for correct day/time
- [ ] Weight Tracking: Verify scheduled for correct day/time
- [ ] Water Reminders: Enable and verify multiple reminders throughout day
- [ ] Birthday: Set test birthdate, verify notification scheduled

#### Edge Cases
- [ ] Enable all notifications simultaneously
- [ ] Disable all notifications
- [ ] Change notification settings multiple times rapidly
- [ ] Test with device timezone changes
- [ ] Test with device reboot (notifications should reschedule)

### Testing Utilities

A test screen has been provided in `lib/screens/testing/notification_test_screen.dart` (optional) for quickly testing notifications without waiting for scheduled times.

## Platform-Specific Notes

### Android
- **Permissions Required**:
  - `POST_NOTIFICATIONS` (Android 13+)
  - `SCHEDULE_EXACT_ALARM` (for precise scheduling)
- **Configuration**: Already set up in `AndroidManifest.xml`
- **Boot Receiver**: Automatically reschedules notifications after device restart

### iOS
- **Permissions**: Requested automatically on first launch
- **Background**: Notifications work even when app is closed
- **Settings**: Users can manage permissions in iOS Settings

## Troubleshooting

### Notifications Not Appearing

1. **Check Permissions**
   - Android: Settings → Apps → CHOSEN → Notifications
   - iOS: Settings → CHOSEN → Notifications

2. **Verify Settings**
   ```dart
   final settings = await NotificationsController.getNotificationSettings();
   print(settings); // Check if notification types are enabled
   ```

3. **Check Scheduled Notifications**
   ```dart
   final pending = await FlutterLocalNotificationsPlugin()
       .pendingNotificationRequests();
   print('Pending notifications: ${pending.length}');
   ```

4. **Timezone Issues**
   - Ensure timezone is properly initialized
   - Check device timezone settings

### Settings Not Persisting

- Verify `shared_preferences` is working
- Check for errors in console
- Try clearing app data and reconfiguring

### Birthday Notification Not Scheduling

- Ensure user has birthdate set in profile
- Verify birthdate format is correct
- Check that notification is enabled in settings

## Best Practices

### For Users
- Enable only notifications you find useful
- Adjust water reminder frequency based on your schedule
- Set birthdate in profile to receive birthday greeting

### For Developers
- Always check notification permissions before scheduling
- Handle timezone changes gracefully
- Test on both Android and iOS
- Provide clear error messages to users
- Use meaningful notification IDs for easy debugging

## Future Enhancements

Potential improvements to consider:

1. **Custom Times**: Allow users to set custom times for each notification
2. **Smart Scheduling**: Adjust reminders based on user activity patterns
3. **Notification Groups**: Group related notifications (e.g., all tracking reminders)
4. **Rich Notifications**: Add images, action buttons, and custom sounds
5. **Analytics**: Track which notifications are most effective
6. **Do Not Disturb**: Respect user's quiet hours
7. **Streak Tracking**: Motivational notifications for maintaining streaks

## Dependencies

- `flutter_local_notifications: ^17.2.3` - Local notification handling
- `timezone: ^0.9.2` - Timezone-aware scheduling
- `shared_preferences: ^2.2.2` - Settings persistence
- `provider: ^6.1.1` - State management

## Support

For issues or questions:
1. Check this documentation
2. Review inline code comments
3. Check Flutter Local Notifications documentation
4. Test on physical device (emulators may have notification limitations)

---

**Last Updated**: November 2025
**Version**: 1.0.0
