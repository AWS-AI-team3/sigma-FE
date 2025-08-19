import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/login_loading_screen.dart';
import '../screens/face_registration_screen.dart';
import '../screens/face_enrollment_screen.dart';
import '../screens/main_dashboard_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String loginLoading = '/login-loading';
  static const String faceRegistration = '/face-registration';
  static const String faceEnrollment = '/face-enrollment';
  static const String main = '/main';

  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const LoginScreen(),
      '/login-loading': (context) => const LoginLoadingScreen(),
      '/face-registration': (context) => const FaceRegistrationScreen(),
      '/face-enrollment': (context) => const FaceEnrollmentScreen(),
      '/main': (context) => const MainDashboardScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case '/login-loading':
        return MaterialPageRoute(builder: (context) => const LoginLoadingScreen());
      case '/face-registration':
        return MaterialPageRoute(builder: (context) => const FaceRegistrationScreen());
      case '/face-enrollment':
        return MaterialPageRoute(builder: (context) => const FaceEnrollmentScreen());
      case '/main':
        return MaterialPageRoute(builder: (context) => const MainDashboardScreen());
      default:
        return null;
    }
  }
}