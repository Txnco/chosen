// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import 'package:chosen/managers/questionnaire_manager.dart';

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
