import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/providers/notification_provider.dart';

/// Testing screen for quickly testing notifications
/// This screen is for development/testing purposes only
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notifications = FlutterLocalNotificationsPlugin();
  final _userController = UserController();
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Notification Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test individual notifications immediately',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildTestButton(
              'Test Daily Planning',
              'Trigger planning notification now',
              () => _testImmediateNotification(
                id: 100,
                title: 'Plan Your Day',
                body: 'Take a moment to plan tomorrow and set your goals!',
              ),
            ),
            _buildTestButton(
              'Test Day Rating',
              'Trigger day rating notification now',
              () => _testImmediateNotification(
                id: 101,
                title: 'Rate Your Day',
                body: 'How was your day? Take a moment to reflect and rate it.',
              ),
            ),
            _buildTestButton(
              'Test Progress Photo',
              'Trigger progress photo notification now',
              () => _testImmediateNotification(
                id: 102,
                title: 'Weekly Progress Photo',
                body: 'Time for your weekly progress photo! Track your transformation.',
              ),
            ),
            _buildTestButton(
              'Test Weight Tracking',
              'Trigger weight notification now',
              () => _testImmediateNotification(
                id: 103,
                title: 'Weekly Weigh-In',
                body: 'Time to record your weight. Consistency is key!',
              ),
            ),
            _buildTestButton(
              'Test Water Reminder',
              'Trigger water notification now',
              () => _testImmediateNotification(
                id: 104,
                title: 'Hydration Time',
                body: 'Remember to drink water! Stay hydrated.',
              ),
            ),
            _buildTestButton(
              'Test Birthday',
              'Trigger birthday notification now',
              () async {
                final user = await _userController.getStoredUser();
                await _testImmediateNotification(
                  id: 105,
                  title: 'Happy Birthday!',
                  body: '${user?.firstName ?? 'Friend'}, wishing you a wonderful birthday! Keep crushing your goals!',
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Scheduled Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test actual scheduling (5 seconds delay)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildTestButton(
              'Schedule Test Notification',
              'Will appear in 5 seconds',
              () => _scheduleTestNotification(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Debug Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTestButton(
              'View Pending Notifications',
              'See all scheduled notifications',
              () => _viewPendingNotifications(),
            ),
            _buildTestButton(
              'View Current Settings',
              'See notification preferences',
              () => _viewSettings(),
            ),
            _buildTestButton(
              'Cancel All Notifications',
              'Clear all scheduled notifications',
              () => _cancelAllNotifications(),
            ),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, String subtitle, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.play_arrow),
        onTap: onPressed,
      ),
    );
  }

  Future<void> _testImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Testing notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      _setStatus('✅ Notification sent: $title');
    } catch (e) {
      _setStatus('❌ Error: $e');
    }
  }

  Future<void> _scheduleTestNotification() async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await _notifications.zonedSchedule(
        999,
        'Test Scheduled Notification',
        'This notification was scheduled 5 seconds ago',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Testing notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _setStatus('✅ Notification scheduled for 5 seconds from now');
    } catch (e) {
      _setStatus('❌ Error scheduling: $e');
    }
  }

  Future<void> _viewPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      final message = 'Pending notifications: ${pending.length}\n\n' +
          pending
              .map((n) => 'ID: ${n.id}, Title: ${n.title}')
              .join('\n');
      _setStatus(message);
    } catch (e) {
      _setStatus('❌ Error: $e');
    }
  }

  Future<void> _viewSettings() async {
    try {
      final settings = await NotificationsController.getNotificationSettings();
      final message = 'Current Settings:\n\n' +
          settings.entries
              .map((e) => '${e.key}: ${e.value ? "✅" : "❌"}')
              .join('\n');
      _setStatus(message);
    } catch (e) {
      _setStatus('❌ Error: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _setStatus('✅ All notifications cancelled');
    } catch (e) {
      _setStatus('❌ Error: $e');
    }
  }

  void _setStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }
}
