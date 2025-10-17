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
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9EA), // Figma 배경색
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고와 앱 이름
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고 이미지
                  Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 46,
                  ),
                  const SizedBox(width: 20),
                  // Sigma 텍스트
                  const Text(
                    'Sigma',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Apple SD Gothic Neo',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 193), // 로고와 버튼 사이 간격

                  // 구글 로그인 버튼
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                )
              else
                GestureDetector(
                  onTap: () {
                    print('🔵 Google Sign In Button Tapped!');
                    _handleGoogleSignIn();
                  },
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4), // Google 파란색
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 35,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google 로고 SVG - 색상 강제 지정
                        SvgPicture.asset(
                          'assets/icons/google_logo.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 버튼 텍스트
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
