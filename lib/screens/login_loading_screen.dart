import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'face_registration_screen.dart';
import 'face_enrollment_screen.dart';
import '../services/google_auth_service.dart';
import '../services/face_auth_service.dart';

class LoginLoadingScreen extends StatefulWidget {
  const LoginLoadingScreen({super.key});

  @override
  State<LoginLoadingScreen> createState() => LoginLoadingScreenState();
}

class LoginLoadingScreenState extends State<LoginLoadingScreen> {
  // 임시로 사용자 등록 상태를 추적하는 정적 변수
  static bool _isUserRegistered = false;
  
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
    _isUserRegistered = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85; // 약 408px
          final containerHeight = screenHeight * 0.85; // 약 660px
          
          // 로고 크기를 윈도우 크기에 따라 조정 (1.2배 확대)
          final logoSize = (containerWidth * 0.18).clamp(72.0, 120.0);
          
          // 고정된 폰트 크기 사용 (직접 수정 가능)
          const double titleFontSize = 40.0;     // SIGMA 타이틀
          const double subtitleFontSize = 11.0;  // Smart Interactive Gesture, Management Assistant
          const double loadingFontSize = 28.0;   // 로그인 중입니다 텍스트
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 상단 로고 섹션 - 로그인 화면과 동일
                    Container(
                      width: double.infinity,
                      height: containerHeight * 0.3, // 전체 높이의 30%
                      padding: EdgeInsets.all(containerWidth * 0.04),
                      child: _buildHeaderSection(
                        logoSize: logoSize,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        containerWidth: containerWidth,
                      ),
                    ),
                    
                    // 로딩 섹션
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(containerWidth * 0.04),
                        padding: EdgeInsets.all(containerWidth * 0.06),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 로딩 인디케이터
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E2981),
                              ),
                              strokeWidth: 3.0,
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // 로그인 중입니다 텍스트
                            Text(
                              '-로그인 중입니다-',
                              style: GoogleFonts.roboto(
                                fontSize: loadingFontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2981),
                                height: 1.0,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 설명 텍스트
                            Text(
                              'Google 계정으로 인증 중...',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
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
        },
      ),
    );
  }

  // 헤더 섹션은 로그인 화면과 동일
  Widget _buildHeaderSection({
    required double logoSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double containerWidth,
  }) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로고
          Container(
            width: logoSize,
            height: logoSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoSize / 2),
              child: Image.asset(
                'assets/images/sigma_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(logoSize / 2),
                    ),
                    child: Icon(
                      Icons.gesture,
                      color: Colors.white,
                      size: logoSize * 0.5,
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(width: containerWidth * 0.06),
          
          // 타이틀 섹션
          _buildTitleSection(titleFontSize, subtitleFontSize),
        ],
      ),
    );
  }

  Widget _buildTitleSection(double titleFontSize, double subtitleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smart Interactive Gesture 텍스트
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'S',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'mart ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'I',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'nteractive ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'G',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'esture',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // SIGMA 메인 타이틀
        Text(
          'SIGMA',
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1.0,
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // Management Assistant 텍스트 - 오른쪽으로 이동
        Padding(
          padding: EdgeInsets.only(left: 72.0), // 왼쪽 패딩 추가로 오른쪽으로 이동
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: 'M',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'anagement ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'A',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'ssistant',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}