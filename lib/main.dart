import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/google_auth_service.dart';

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
      home: const AuthCheckScreen(),
    );
  }
}

// 로그인 상태 확인 화면
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final googleAuth = GoogleAuthService();

    // 구글 로그인만 확인 (얼굴 인증 스킵)
    final isGoogleLoggedIn = await googleAuth.isLoggedIn();

    print('🔐 Auth Check: Google=$isGoogleLoggedIn');

    await Future.delayed(const Duration(seconds: 1)); // 스플래시 효과

    if (mounted) {
      if (isGoogleLoggedIn) {
        // 구글 로그인 완료 → 홈 화면으로
        print('✅ Google login complete → HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // 로그인 필요 → 로그인 화면으로
        print('🔑 Login needed → LoginScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gesture, size: 100, color: Colors.white),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
