import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigma_flutter_ui/screens/login_screen.dart';
import 'package:sigma_flutter_ui/screens/settings_screen.dart';
import 'package:sigma_flutter_ui/screens/tracking_screen.dart';
import 'package:sigma_flutter_ui/services/python_service.dart';

// Figma Node ID: 1-523 (메인 페이지 - 얼굴 인증 성공 후)
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  bool _isSettingsHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.85;

          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 상단 헤더 바
                    Positioned(
                      top: 21,
                      left: 17,
                      child: Container(
                        width: containerWidth * 0.92,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6186FF),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 프로필 아이콘 배경 원 (왼쪽)
                            Positioned(
                              left: 17,
                              top: 9,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFFFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                            // 프로필 아이콘
                            Positioned(
                              left: 12,
                              top: 4,
                              child: Container(
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 50,
                                  color: Color(0xFF0D0D11),
                                ),
                              ),
                            ),

                            // AWS님 텍스트
                            Positioned(
                              left: 68,
                              top: 10,
                              child: Text(
                                'AWS님',
                                style: GoogleFonts.roboto(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),

                            // 설정 아이콘 (오른쪽) - 마우스 오버 효과 적용
                            Positioned(
                              right: 14,
                              top: 7,
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _isSettingsHovered = true),
                                onExit: (_) => setState(() => _isSettingsHovered = false),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 45,
                                    height: 45,
                                    
                                    child: Icon(
                                      Icons.settings,
                                      size: 30,
                                      color: _isSettingsHovered ? const Color.fromARGB(255, 255, 255, 255) : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FREE 텍스트
                    Positioned(
                      left: 32,
                      top: 75,
                      child: Text(
                        'FREE',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.67,
                        ),
                      ),
                    ),

                    // 트레킹 시작하기 버튼 (메인)
                    Positioned(
                      left: containerWidth * 0.2,
                      top: 234,
                      child: Container(
                        width: containerWidth * 0.57,
                        height: 103,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D11),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await PythonService.startHandTracking();

                            if (success) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TrackingScreen()),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('손 트래킹이 시작되었습니다'),
                                  backgroundColor: Color(0xFF6186FF),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('손 트래킹 시작에 실패했습니다'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D0D11),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            '트레킹 시작하기',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Log out 버튼 (하단 오른쪽)
                    Positioned(
                      right: 15,
                      bottom: 16,
                      child: Container(
                        width: 190,
                        height: 51,
                        decoration: BoxDecoration(
                          color: const Color(0xFF677BFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF4E66FF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF677BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Log out',
                                style: GoogleFonts.roboto(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform.rotate(
                                angle: 3.14159,
                                child: Transform.scale(
                                  scaleY: -1,
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 15,
                                    color: Colors.white,
                                  ),
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
          );
        },
      ),
    );
  }
}

