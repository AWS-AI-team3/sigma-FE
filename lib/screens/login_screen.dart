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
          final containerHeight = screenHeight * 0.85;
          final logoSize = (containerWidth * 0.18).clamp(72.0, 120.0);
          const double titleFontSize = 40.0;
          const double subtitleFontSize = 11.0;
          const double loginFontSize = 28.0;
          const double buttonFontSize = 16.0;

          return Center(
            child: Stack(
              children: [
                // 로그인 메인 박스
                Container(
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
                      // 상단 로고+타이틀
                      Container(
                        width: double.infinity,
                        height: containerHeight * 0.23,
                        padding: EdgeInsets.all(containerWidth * 0.04),
                        child: _buildHeaderSection(
                          logoSize: logoSize,
                          titleFontSize: titleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          containerWidth: containerWidth,
                        ),
                      ),
                      // 로그인 쪽(구글 등)
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
                // 파란색 동그라미 X 버튼
                Positioned(
                  top: 18,
                  right: 18,
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
              ],
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
          // 로고 영역
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
          // 타이틀/부제목
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
        // Smart Interactive Gesture
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            children: [
              TextSpan(text: 'S', style: TextStyle(color: Color(0xFF0004FF))),
              TextSpan(text: 'mart ', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'I', style: TextStyle(color: Color(0xFF0004FF))),
              TextSpan(text: 'nteractive ', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'G', style: TextStyle(color: Color(0xFF0004FF))),
              TextSpan(text: 'esture', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        SizedBox(height: titleFontSize * 0.1),
        // SIGMA main
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
        // Management Assistant (오른쪽 정렬용 패딩)
        Padding(
          padding: EdgeInsets.only(left: 72.0),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'M', style: TextStyle(color: Color(0xFF0004FF))),
                TextSpan(text: 'anagement ', style: TextStyle(color: Colors.black)),
                TextSpan(text: 'A', style: TextStyle(color: Color(0xFF0004FF))),
                TextSpan(text: 'ssistant', style: TextStyle(color: Colors.black)),
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
        Container(
          width: containerWidth * 0.8,
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
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginLoadingScreen()),
    );
  }
}

///

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({super.key, required this.onTap});

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
        ? base.withOpacity(0.5)
        : (_hovering ? base.withOpacity(0.8) : base);

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
                color: Colors.black.withOpacity(0.13),
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
