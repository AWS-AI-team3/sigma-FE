import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_loading_screen.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 사용 가능한 공간에 따라 동적으로 크기 조정
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
          const double loginFontSize = 28.0;     // Login 텍스트
          const double buttonFontSize = 16.0;    // 버튼 텍스트
          
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
                    // 상단 로고 섹션 - 황금비율에 맞춰 조정
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
                    
                    // 로그인 섹션 - 나머지 공간 사용
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(containerWidth * 0.04),
                        padding: EdgeInsets.all(containerWidth * 0.06),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _buildLoginSection(
                          context: context,
                          loginFontSize: loginFontSize,
                          buttonFontSize: buttonFontSize,
                          containerWidth: containerWidth,
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

  Widget _buildHeaderSection({
    required double logoSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double containerWidth,
  }) {
    // 로고와 텍스트를 항상 가로로 배치하고 가운데 정렬
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

  Widget _buildLoginSection({
    required BuildContext context,
    required double loginFontSize,
    required double buttonFontSize,
    required double containerWidth,
  }) {
    return Column(
      children: [
        SizedBox(height: loginFontSize * 0.5),
        
        // Login 타이틀
        Text(
          'Login',
          style: GoogleFonts.roboto(
            fontSize: loginFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2981),
            height: 1.0,
          ),
        ),
        
        SizedBox(height: loginFontSize * 1.5),
        
        // Google 로그인 버튼
        Container(
          width: containerWidth * 0.8, // 전체 너비가 아닌 80%로 제한
          height: (containerWidth * 0.1).clamp(50.0, 60.0),
          child: ElevatedButton(
            onPressed: () {
              _handleGoogleLogin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google 로고 이미지 (1.2배 확대)
                Image.asset(
                  'assets/images/google_logo.png',
                  width: buttonFontSize * 1.56, // 1.3 * 1.2 = 1.56
                  height: buttonFontSize * 1.56,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: buttonFontSize * 1.56, // 1.2배 확대
                      height: buttonFontSize * 1.56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(buttonFontSize * 0.78), // 0.65 * 1.2
                      ),
                      child: Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: buttonFontSize,
                      ),
                    );
                  },
                ),
                SizedBox(width: buttonFontSize * 0.8),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.roboto(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
      ],
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    // 로딩 화면으로 이동 - 로딩 화면에서 실제 로그인 처리
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginLoadingScreen()),
    );
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
}