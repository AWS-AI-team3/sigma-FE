import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/google_auth_service.dart';
import '../services/face_auth_service.dart';
import '../themes/app_theme.dart';
import '../widgets/sigma_branding_text.dart';

class LoginLoadingScreen extends StatefulWidget {
  const LoginLoadingScreen({super.key});

  @override
  State<LoginLoadingScreen> createState() => LoginLoadingScreenState();
}

class LoginLoadingScreenState extends State<LoginLoadingScreen> {
  // 임시로 사용자 등록 상태를 추적하는 정적 변수
  
  @override
  void initState() {
    super.initState();
    // 실제 Google OAuth 및 얼굴 등록 확인 처리
    _handleGoogleLogin();
  }

  Future<void> _handleGoogleLogin() async {
    try {
      // Google 인증 시작
      final Map<String, dynamic>? result = await GoogleAuthService.signInWithGoogle();
      
      if (result != null && result['success'] == true) {
        // 로그인 성공 - 얼굴 등록 여부 확인
        final faceCheckResult = await FaceAuthService.checkRegistrationAndGetPresignedUrl();
        
        if (mounted) {
          if (faceCheckResult != null) {
            if (faceCheckResult['sucess'] == true || faceCheckResult['success'] == true) {
              // 얼굴 등록 완료 - 얼굴 인증 화면으로 이동 (presigned URL 데이터 전달)
              Navigator.pushReplacementNamed(
                context, 
                '/face-registration',
                arguments: faceCheckResult['data'],
              );
            } else if (faceCheckResult['error'] != null && 
                       faceCheckResult['error']['code'] == 'FACE_NOT_REGISTERED') {
              // 얼굴 등록 안됨 - 얼굴 등록 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(context, '/face-enrollment', (route) => false);
            } else {
              // 기타 오류 - 얼굴 등록 화면으로 이동 (기본값)
              Navigator.pushNamedAndRemoveUntil(context, '/face-enrollment', (route) => false);
            }
          } else {
            // API 호출 실패 - 얼굴 등록 화면으로 이동 (기본값)
            Navigator.pushNamedAndRemoveUntil(context, '/face-enrollment', (route) => false);
          }
        }
      } else {
        // 로그인 실패 - 로그인 화면으로 돌아가기
        if (mounted) {
          Navigator.pop(context);
          _showErrorDialog(context, result?['error'] ?? 'Google login failed');
        }
      }
    } catch (error) {
      // 예외 처리 - 로그인 화면으로 돌아가기
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, 'An error occurred: $error');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  // 사용자 등록 완료 시 호출할 정적 메소드
  static void setUserRegistered() {
    // 더 이상 사용되지 않는 메소드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/sigma_logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 23),
                    
                    // Smart Interactive Gesture text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: 'S',
                            style: TextStyle(color: AppTheme.sigmaBlue),
                          ),
                          TextSpan(
                            text: 'mart ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'I',
                            style: TextStyle(color: AppTheme.sigmaBlue),
                          ),
                          TextSpan(
                            text: 'nteractive ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'G',
                            style: TextStyle(color: AppTheme.sigmaBlue),
                          ),
                          TextSpan(
                            text: 'esture',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // SIGMA title
                    Text(
                      'SIGMA',
                      style: const TextStyle(
                        fontFamily: 'AppleSDGothicNeo',
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Management Assistant text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: 'M',
                            style: TextStyle(color: AppTheme.sigmaBlue),
                          ),
                          TextSpan(
                            text: 'anagement ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'A',
                            style: TextStyle(color: AppTheme.sigmaBlue),
                          ),
                          TextSpan(
                            text: 'ssistant',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Loading indicator and text replacing Google Sign In Button
                    Container(
                      width: 413,
                      height: 59,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.borderGray,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Loading indicator
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.sigmaBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '로그인 중입니다...',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom section with Euler, X, and AWS logos
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/euler_logo.png',
                    width: 40,
                    height: 14,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Euler',
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.logoGray,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/x_logo.png',
                    width: 8,
                    height: 8,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 5.238,
                        height: 5.238,
                        decoration: const BoxDecoration(
                          color: AppTheme.logoGray,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/aws_logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.cloud,
                        color: AppTheme.logoGray,
                        size: 24,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}