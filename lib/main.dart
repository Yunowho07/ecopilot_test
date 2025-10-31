// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import the splash screen
import 'screens/onboarding_screen.dart';
import 'auth/landing.dart';
import 'auth/login.dart';
import 'auth/signup.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize Firebase (required for authentication check in splash screen)
  // Use platform-specific options (important for web builds)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications (timezone and plugin)
  try {
    await NotificationService().init();
  } catch (e) {
    // Non-fatal: continue without scheduled notifications
  }
  runApp(const EcoPilotApp());
}

class EcoPilotApp extends StatelessWidget {
  const EcoPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF1db954),
        scaffoldBackgroundColor: Colors.white,
      ),
      // Named routes for consistent navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthLandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
