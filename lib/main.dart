import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'controllers/notifications_controller.dart';
import 'managers/session_manager.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/water/water_tracking_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/tracking/weight_tracking_screen.dart';
import 'screens/tracking/day_rating_tracking_screen.dart';
import 'screens/tracking/progress_photos_screen.dart';
import 'screens/events/event_screen.dart';
import 'screens/testing/notification_test_screen.dart';
import 'screens/messaging/chat_screen.dart';

// Global navigator key for handling navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications with navigator key
  await NotificationsController.initialize(navigatorKey);

  // IMMEDIATELY cancel all old notifications before app even starts
  await NotificationsController.clearAllPendingNotifications();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationsOnStartup();
    }
  }

  /// Initialize and sync notifications on app startup
  Future<void> _initializeNotifications() async {
    // Sync immediately after initialization
    await _syncNotificationsOnStartup();
  }

  /// Sync notifications with backend on app startup
  Future<void> _syncNotificationsOnStartup() async {
    try {
      final user = await SessionManager.getCurrentUser();
      if (user != null) {
        print('Syncing notifications for user: ${user.firstName}');
        
        // Sync with backend and reschedule with proper payloads
        await NotificationsController.syncPreferencesWithApi(user);
        
        print('Notifications synced successfully');
      } else {
        print('No user found, skipping notification sync');
      }
    } catch (e) {
      print('Error syncing notifications on startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Chosen',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          
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
            '/day-rating': (_) => const DayRatingTrackingScreen(),
            '/progress-photos': (_) => const ProgressPhotosScreen(),
            '/events': (context) => const EventScreen(),
            '/notification-test': (_) => const NotificationTestScreen(),
            '/chat': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return ChatScreen(
                conversation: args['conversation'],
                currentUserId: args['currentUserId'],
              );
            },
          },

          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      },
    );
  }
}