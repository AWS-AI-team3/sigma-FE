import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import '../services/face_auth_service.dart';
import 'face_enrollment_screen.dart';
import 'face_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    print('🚀 _handleGoogleSignIn called');
    setState(() {
      _isLoading = true;
    });
    print('⏳ Loading state set to true');

    try {
      print('📞 Calling signInWithGoogle...');
      final result = await _authService.signInWithGoogle();
      print('📱 signInWithGoogle returned: $result');

      if (result != null && result['success'] == true && mounted) {
        // 구글 로그인 성공 → 얼굴 등록 여부 확인
        print('✅ Google login success, checking face registration...');
        final faceCheckResult =
            await FaceAuthService.checkRegistrationAndGetPresignedUrl();

        if (mounted) {
          if (faceCheckResult != null) {
            if (faceCheckResult['sucess'] == true ||
                faceCheckResult['success'] == true) {
              // 얼굴 등록 완료 - 얼굴 인증 화면으로 이동
              print('👤 Face registered, going to authentication');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceRegistrationScreen(),
                  settings: RouteSettings(arguments: faceCheckResult['data']),
                ),
              );
            } else if (faceCheckResult['error'] != null &&
                faceCheckResult['error']['code'] == 'FACE_NOT_REGISTERED') {
              // 얼굴 등록 안됨 - 얼굴 등록 화면으로 이동
              print('📸 Face not registered, going to enrollment');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceEnrollmentScreen(),
                ),
              );
            } else {
              // 기타 오류 - 얼굴 등록 화면으로 이동
              print('⚠️ Unknown response, going to enrollment');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceEnrollmentScreen(),
                ),
              );
            }
          } else {
            // API 호출 실패 - 얼굴 등록 화면으로 이동
            print('❌ API call failed, going to enrollment');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FaceEnrollmentScreen(),
              ),
            );
          }
        }
      } else {
        // error는 Map<String, dynamic> 형태
        final error = result?['error'];
        final errorMessage = error is Map
            ? (error['message'] ?? '로그인에 실패했습니다.')
            : '로그인에 실패했습니다.';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('❌ Error during login: $e');
      _showErrorDialog('로그인 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 또는 앱 이름
                  const Icon(Icons.gesture, size: 120, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'Gesture Browser',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MediaPipe Hand Tracking',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 80),

                  // 구글 로그인 버튼
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        print('🔵 GestureDetector Tapped!');
                        _handleGoogleSignIn();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.login,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Google로 로그인',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // 안내 문구
                  const Text(
                    '로그인 후 얼굴 인증을 진행합니다',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
