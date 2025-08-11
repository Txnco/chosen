import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'managers/session_manager.dart';
import 'package:chosen/managers/questionnaire_manager.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/water/water_tracking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartupScreen() async {
    try {
      bool isValid = await SessionManager.isTokenValid();
      
      if (!isValid) {
        return const LoginScreen();
      }

      // If token is valid, check questionnaire status
      bool isQuestionnaireCompleted = await QuestionnaireManager.isQuestionnaireCompleted();
      
      if (!isQuestionnaireCompleted) {
        return const QuestionnaireScreen();
      }
      
      return const DashboardScreen();
    } catch (e) {
      // Fallback to login on any error
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chosen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Avenir',
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: FutureBuilder<Widget>(
        future: _getStartupScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error loading app')),
            );
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return const Scaffold(
              body: Center(child: Text('Unknown error')),
            );
          }
        },
      ),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/questionnaire': (context) => const QuestionnaireScreen(),
        '/messaging': (context) => const MessagingScreen(),
        '/water-tracking': (context) => const WaterTrackingScreen(),
      },
    );
  }
}