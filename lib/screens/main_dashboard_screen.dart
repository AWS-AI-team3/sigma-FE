import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';
import 'face_registration_screen.dart';
import '../services/python_service.dart';
import '../services/face_auth_service.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import '../providers/settings_provider.dart';

// Figma Node ID: 1-523 (메인 페이지 - 얼굴 인증 성공 후)
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  String _userName = 'AWS님';
  String? _profileUrl;
  String _subscriptStatus = 'FREE';
  bool _isSettingsHovered = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await UserService.getUserInfo();
    if (userInfo != null && userInfo['sucess'] == true) {
      final data = userInfo['data'];
      if (mounted) {
        setState(() {
          _userName = data['userName'] ?? 'AWS님';
          _profileUrl = data['profileUrl'];
          _subscriptStatus = data['subscriptStatus'] ?? 'FREE';
        });
      }
    }
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
                        width: containerWidth * 0.92, // 626px 상대 크기
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
                                child: _profileUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _profileUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.account_circle,
                                              size: 50,
                                              color: Color(0xFF0D0D11),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.account_circle,
                                        size: 50,
                                        color: Color(0xFF0D0D11),
                                      ),
                              ),
                            ),

                            // 사용자 이름 텍스트
                            Positioned(
                              left: 68,
                              top: 10,
                              child: Text(
                                _userName,
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

                    // 구독 상태 텍스트
                    Positioned(
                      left: 32,
                      top: 75,
                      child: Text(
                        _subscriptStatus,
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
                      left: containerWidth * 0.2, // 146px 상대 크기
                      top: 234,
                      child: Container(
                        width: containerWidth * 0.57, // 392px 상대 크기
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
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            // 1. 얼굴 인증 세션 체크
                            final sessionResult = await FaceAuthService.checkFaceSession();
                            
                            if (sessionResult == null) {
                              _showFaceAuthRequiredDialog(context);
                              return;
                            }
                            
                            if (sessionResult['error'] != null && sessionResult['error']['code'] == 'FACE_UNAUTHORIZED') {
                              _showFaceAuthRequiredDialog(context);
                              return;
                            }
                            
                            // 2. 세션 체크 성공 시 트래킹 시작
                            if (sessionResult['sucess'] == true || sessionResult['success'] == true) {
                              // 혹시 남아있는 프로세스 정리
                              print('Ensuring clean state before starting tracking...');
                              await PythonService.cleanup();
                              await Future.delayed(const Duration(milliseconds: 300));
                              
                              final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                              print('Starting tracking with showSkeleton: ${settingsProvider.showSkeleton}');
                              final success = await PythonService.startHandTracking(
                                showSkeleton: settingsProvider.showSkeleton
                              );
                              
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
                            } else {
                              _showFaceAuthRequiredDialog(context);
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
                          onPressed: () async {
                            // 서버 로그아웃 API 호출
                            await GoogleAuthService.logout();
                            
                            // 로그인 화면으로 돌아가기
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
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
                                angle: 3.14159, // 180도 회전
                                child: Transform.scale(
                                  scaleY: -1, // Y축 반전
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

  void _showFaceAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75),
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      '얼굴인증이 아직 진행되지 않았습니다.',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '얼굴 인증을 먼저 완료해주세요.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 27,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9CA3AF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            ),
                            child: Text(
                              '취소',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 100,
                          height: 27,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FaceRegistrationScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF185ABD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            ),
                            child: Text(
                              '인증하기',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
