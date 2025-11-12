// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import 'package:chosen/managers/questionnaire_manager.dart';
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/controllers/user_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideStart();
  }

  Future<void> _decideStart() async {
    try {
      final isValid = await SessionManager.isTokenValid();
      if (!mounted) return;

      if (!isValid) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Sync notifications with API after successful login
      // This ensures all notifications have proper payloads and are up to date with DB
      try {
        final userController = UserController();
        final user = await userController.getStoredUser();
        await NotificationsController.syncPreferencesWithApi(user);
        print('Notifications synced with API');
      } catch (e) {
        print('Failed to sync notifications: $e');
        // Continue anyway - notifications will sync later
      }

      final done = await QuestionnaireManager.isQuestionnaireCompleted();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        done ? '/dashboard' : '/questionnaire',
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
