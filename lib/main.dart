import 'package:app/screens/dashboard/dashboard_screen.dart';
import 'package:app/screens/login/login_screen.dart';
import 'package:app/screens/onboard/onboard_screen_one.dart';
import 'package:app/screens/register/register_screen.dart';
import 'package:app/screens/splash/splash_screen.dart';
import 'package:app/screens/extra_dose/extra_dose_screen.dart';
import 'package:app/screens/vitamin_k/vitamin_k_screen.dart';
import 'package:app/screens/extra_medication/extra_medication_screen.dart';
import 'package:app/screens/symptoms/symptoms_screen.dart';
import 'package:app/screens/warmup/warmup_screen.dart';
import 'package:app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/onboard1': (context) => const OnboardScreenOne(),
        '/extra-dose': (context) => const ExtraDoseScreen(),
        '/vitamin-k': (context) => const VitaminKScreen(),
        '/extra-medication': (context) => const ExtraMedicationScreen(),
        '/symptoms': (context) => const SymptomsScreen(),
        '/warmup': (context) => const WarmupScreen(),
      },
      home: SplashScreen(),
    );
  }
}
