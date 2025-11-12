import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'controllers/notifications_controller.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/water/water_tracking_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/tracking/weight_tracking_screen.dart';
import 'screens/tracking/progress_photos_screen.dart';
import 'screens/tracking/day_rating_tracking_screen.dart';
import 'screens/events/event_screen.dart';
import 'screens/testing/notification_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationsController.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Global navigation key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Chosen',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,

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
            '/progress-photos': (_) => const ProgressPhotosScreen(),
            '/day-rating': (_) => const DayRatingTrackingScreen(),
            '/events': (context) => const EventScreen(),
            '/notification-test': (_) => const NotificationTestScreen(),
          },

          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      },
    );
  }
}