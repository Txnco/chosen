import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/water/water_tracking_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

      initialRoute: '/splash',

      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/questionnaire': (_) => const QuestionnaireScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/messaging': (_) => const MessagingScreen(),
        '/water-tracking': (_) => const WaterTrackingScreen(),
        '/settings': (_) => const SettingsScreen(),
      },

      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}