import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_loading_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.75;
          final logoSize = (containerWidth * 0.18).clamp(72.0, 120.0);
          const double titleFontSize = 40.0;
          const double subtitleFontSize = 11.0;
          const double loginFontSize = 28.0;
          const double buttonFontSize = 16.0;
          final double loginBoxHeight = containerHeight * 0.38;
          return Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CloseButton(
                      onTap: () {
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else {
                          exit(0);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 48), // 엑스 버튼 밑 여백
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // 상단 로고/타이틀
                        SizedBox(
                          height: containerHeight * 0.21,
                          child: _buildHeaderSection(
                            logoSize: logoSize,
                            titleFontSize: titleFontSize,
                            subtitleFontSize: subtitleFontSize,
                            containerWidth: containerWidth,
                          ),
                        ),
                        const Spacer(),
                        // 로그인 박스 (더 늘어난 높이)
                        Container(
                          height: loginBoxHeight,
                          margin: EdgeInsets.symmetric(
                              vertical: containerWidth * 0.01,
                              horizontal: containerWidth * 0.04),
                          padding: EdgeInsets.all(containerWidth * 0.05),
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
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
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
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // 박스 내부 요소 자동 중앙 정렬
        children: [
          // 여기만 수정됨: 'Login' 텍스트→이미지
          SizedBox(
            height: loginFontSize * 1.2,
            child: Image.asset(
              'assets/images/logintxt.png',
              fit: BoxFit.contain,
              // 원하는 경우 width, height 등을 조정하세요
            ),
          ),
          SizedBox(height: loginFontSize * 1.0),
          // 버튼의 크기와 패딩을 충분히 크게
          SizedBox(
            width: containerWidth * 0.82,
            height: (containerWidth * 0.13).clamp(60.0, 80.0),
            child: ElevatedButton(
              onPressed: () {
                _handleGoogleLogin(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: buttonFontSize * 1.56,
                    height: buttonFontSize * 1.56,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: buttonFontSize * 1.56,
                        height: buttonFontSize * 1.56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          borderRadius: BorderRadius.circular(buttonFontSize * 0.78),
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
      ),
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginLoadingScreen()),
    );
  }

}

// CloseButton 클래스(원본 그대로)
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}
class _CloseButtonState extends State<_CloseButton> {
  bool _hovering = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final Color base = const Color(0xFF3C4FE0);
    Color bg = _pressed
        ? base.withValues(alpha: 0.5)
        : (_hovering ? base.withValues(alpha: 0.8) : base);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.close, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
