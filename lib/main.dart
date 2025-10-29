import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/water/water_tracking_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/tracking/weight_tracking_screen.dart';
import 'screens/events/event_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Chosen',
          debugShowCheckedModeBanner: false,
          
          // Use your custom themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          initialRoute: '/splash',

          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/questionnaire': (_) => const QuestionnaireScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/messaging': (_) => const MessagingScreen(),
            '/water-tracking': (_) => const WaterTrackingScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/weight-tracking': (_) => const WeightTrackingScreen(),
            '/events': (context) => const EventScreen(),
          },

          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      },
    );
  }
}