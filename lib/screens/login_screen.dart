import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/google_auth_service.dart';
import '../services/face_auth_service.dart';
import 'face_enrollment_screen.dart';
import 'face_authentication_screen.dart';

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
                  builder: (context) => const FaceAuthenticationScreen(),
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
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;

    // Figma design dimensions: 836x584
    // Scale factor to fit screen width (with some padding)
    final containerWidth = screenWidth * 0.9; // 90% of screen width
    final scale = containerWidth / 836;
    final containerHeight = 584 * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9EA), // Figma 배경색
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: containerWidth,
            height: containerHeight,
            child: Stack(
              children: [
                // Logo - Figma: x=331 (relative), y=218, w=48, h=46
                Positioned(
                  left: 331 * scale,
                  top: 218 * scale,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 48 * scale,
                    height: 46 * scale,
                  ),
                ),
                // Sigma text - Figma: x=385 (relative), y=224, w=120, h=37
                Positioned(
                  left: 385 * scale,
                  top: 224 * scale,
                  child: Text(
                    'Sigma',
                    style: TextStyle(
                      fontSize: 40 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Apple SD Gothic Neo',
                    ),
                  ),
                ),
                // Google button - Figma: x=269 (relative), y=411, w=300, h=48
                Positioned(
                  left: 269 * scale,
                  top: 411 * scale,
                  child: _isLoading
                      ? SizedBox(
                          width: 300 * scale,
                          height: 48 * scale,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            print('🔵 Google Sign In Button Tapped!');
                            _handleGoogleSignIn();
                          },
                          child: Container(
                            width: 300 * scale,
                            height: 48 * scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4), // Google Blue
                              borderRadius: BorderRadius.circular(12 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 35 * scale,
                                  offset: Offset(0, 5 * scale),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google logo
                                SvgPicture.asset(
                                  'assets/icons/google_logo.svg',
                                  width: 20 * scale,
                                  height: 20 * scale,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 16 * scale),
                                // Button text
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
