import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/managers/session_manager.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notifications = FlutterLocalNotificationsPlugin();
  final _userController = UserController();
  String _statusMessage = '';
  List<int> _pendingIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);
    final ids = await NotificationsController.getPendingNotificationIds();
    setState(() {
      _pendingIds = ids;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CRITICAL WARNING CARD
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'OLD NOTIFICATIONS FIX',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '⚠️ If you have OLD notifications in your notification tray (from before the payload fix), they won\'t work.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '✅ SOLUTION: Manually swipe away ALL notifications from your tray, then use the buttons below to test.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TEST WITH PAYLOAD - These will work!
                  const Text(
                    'Test Notifications WITH Payloads',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These notifications have proper payloads and WILL navigate correctly',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  _buildTestButton(
                    'Test Water Tracking Navigation',
                    'Tap this notification → Should open Water Tracking',
                    () => _testNotificationWithPayload(
                      id: 1001,
                      title: 'Hydration Time',
                      body: 'TAP ME to test water tracking navigation',
                      payload: 'water_intake',
                    ),
                    Colors.blue,
                  ),

                  _buildTestButton(
                    'Test Day Rating Navigation',
                    'Tap this notification → Should open Day Rating',
                    () => _testNotificationWithPayload(
                      id: 1002,
                      title: 'Rate Your Day',
                      body: 'TAP ME to test day rating navigation',
                      payload: 'day_rating',
                    ),
                    Colors.orange,
                  ),

                  _buildTestButton(
                    'Test Weight Tracking Navigation',
                    'Tap this notification → Should open Weight Tracking',
                    () => _testNotificationWithPayload(
                      id: 1003,
                      title: 'Weekly Weigh-In',
                      body: 'TAP ME to test weight tracking navigation',
                      payload: 'weight_tracking',
                    ),
                    Colors.purple,
                  ),

                  _buildTestButton(
                    'Test Progress Photos Navigation',
                    'Tap this notification → Should open Progress Photos',
                    () => _testNotificationWithPayload(
                      id: 1004,
                      title: 'Weekly Progress Photo',
                      body: 'TAP ME to test progress photos navigation',
                      payload: 'progress_photo',
                    ),
                    Colors.green,
                  ),

                  _buildTestButton(
                    'Test Events Navigation',
                    'Tap this notification → Should open Events/Calendar',
                    () => _testNotificationWithPayload(
                      id: 1005,
                      title: 'Plan Your Day',
                      body: 'TAP ME to test events navigation',
                      payload: 'daily_planning',
                    ),
                    Colors.teal,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // COMPLETE RESET SECTION
                  const Text(
                    'Nuclear Option',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildTestButton(
                    'Clear Everything & Reschedule',
                    'Clears all notifications and reschedules with payloads',
                    () => _clearAndReschedule(),
                    Colors.red,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // PENDING NOTIFICATIONS
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pending Notifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pendingIds.isEmpty
                                ? 'No pending notifications'
                                : 'IDs: ${_pendingIds.join(", ")}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Count: ${_pendingIds.length}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadPendingNotifications,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh List'),
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
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    VoidCallback onPressed,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(Icons.notifications_active, color: color, size: 32),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.play_arrow, color: color),
        onTap: onPressed,
      ),
    );
  }

  Future<void> _testNotificationWithPayload({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Testing notifications with payloads',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload, // THIS IS THE KEY - payload is included!
      );
      _setStatus('✅ Notification sent with payload: "$payload"\n\nNow TAP the notification in your tray to test navigation!');
    } catch (e) {
      _setStatus('❌ Error: $e');
    }
  }

  Future<void> _clearAndReschedule() async {
    setState(() => _isLoading = true);
    
    final user = await SessionManager.getCurrentUser();
    
    // Clear everything
    await NotificationsController.clearAllPendingNotifications();
    
    // Reschedule with proper payloads
    await NotificationsController.syncPreferencesWithApi(user);
    
    await _loadPendingNotifications();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cleared and rescheduled all notifications!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    _setStatus('✅ All notifications cleared and rescheduled.\n\nManually clear your notification tray, then wait for new notifications to appear.');
  }

  void _setStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }
}