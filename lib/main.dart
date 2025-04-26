import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import 'notification_service.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'forgot_password.dart';
import 'home_page.dart';
import 'addtask_page.dart';
// import 'settings_page.dart';
import 'package:testapp/settings_page.dart' as settings;
// import 'package:testapp/addtask_page.dart'; // If you still need this import.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('appPreferences');
  await NotificationService.initialize();

  runApp(MyApp(shouldShowLanding: await shouldShowLandingPage()));
}

// 🔹 **Function to check if the landing page should be shown**
Future<bool> shouldShowLandingPage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('seenLandingPage') ?? true;
}

// 🔹 **Main App Widget**
class MyApp extends StatelessWidget {
  final bool shouldShowLanding;
  const MyApp({super.key, required this.shouldShowLanding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TimeMate',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: AuthWrapper(shouldShowLanding: shouldShowLanding),
      routes: {
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/add_task': (context) => const AddTaskPage(),
        '/settings': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return settings.SettingsPage(userName: user.displayName ?? "");
          } else {
            return const LoginPage();
          }
        },
        '/home': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return HomePage(userName: user.displayName ?? "User");
          } else {
            return const LoginPage();
          }
        },
      },
    );
  }
}

// 🔹 **Authentication Wrapper**
class AuthWrapper extends StatelessWidget {
  final bool shouldShowLanding;
  const AuthWrapper({super.key, required this.shouldShowLanding});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final User? user = snapshot.data;

        // First check if the landing page should be shown
        if (shouldShowLanding) {
          return const LandingPage();
        }

        // Then decide based on whether the user is logged in or not
        if (user == null) {
          return const LoginPage();
        } else {
          return HomePage(userName: user.displayName ?? "User");
        }
      },
    );
  }
}
