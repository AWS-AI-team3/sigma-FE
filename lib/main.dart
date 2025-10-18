import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/face_authentication_screen.dart';
import 'screens/face_enrollment_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GestureBrowserApp());
}

class GestureBrowserApp extends StatelessWidget {
  const GestureBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: settings,
            );
          case '/face-auth':
            return MaterialPageRoute(
              builder: (context) => const FaceAuthenticationScreen(),
              settings: settings,
            );
          case '/face-enroll':
            return MaterialPageRoute(
              builder: (context) => const FaceEnrollmentScreen(),
              settings: settings,
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
        }
      },
    );
  }
}
