import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigma_flutter_ui/screens/login_screen.dart';
import 'package:sigma_flutter_ui/screens/settings_screen.dart';
import 'package:sigma_flutter_ui/screens/tracking_screen.dart';
<<<<<<< HEAD
import 'package:sigma_flutter_ui/screens/face_registration_screen.dart';
import 'package:sigma_flutter_ui/services/python_service.dart';
import 'package:sigma_flutter_ui/services/face_auth_service.dart';
import 'package:sigma_flutter_ui/services/user_service.dart';
import 'package:sigma_flutter_ui/services/google_auth_service.dart';
=======
import 'package:sigma_flutter_ui/services/python_service.dart';
>>>>>>> round_camera

// Figma Node ID: 1-523 (메인 페이지 - 얼굴 인증 성공 후)
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
<<<<<<< HEAD
  String _userName = 'AWS님';
  String? _profileUrl;
  String _subscriptStatus = 'FREE';

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
=======
  bool _isSettingsHovered = false;
>>>>>>> round_camera

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
<<<<<<< HEAD
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.85;
          
=======

          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.85;

>>>>>>> round_camera
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
<<<<<<< HEAD
                        width: containerWidth * 0.92, // 626px 상대 크기
=======
                        width: containerWidth * 0.92,
>>>>>>> round_camera
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
<<<<<<< HEAD
                            
=======

>>>>>>> round_camera
                            // 프로필 아이콘
                            Positioned(
                              left: 12,
                              top: 4,
                              child: Container(
                                width: 50,
                                height: 50,
<<<<<<< HEAD
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
=======
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 50,
                                  color: Color(0xFF0D0D11),
                                ),
                              ),
                            ),

                            // AWS님 텍스트
>>>>>>> round_camera
                            Positioned(
                              left: 68,
                              top: 10,
                              child: Text(
<<<<<<< HEAD
                                _userName,
=======
                                'AWS님',
>>>>>>> round_camera
                                style: GoogleFonts.roboto(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
<<<<<<< HEAD
                            
                            // 설정 아이콘 (오른쪽)
                            Positioned(
                              right: 14,
                              top: 7,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  );
                                },
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  child: const Icon(
                                    Icons.settings,
                                    size: 30,
                                    color: Colors.black,
=======

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
>>>>>>> round_camera
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
<<<<<<< HEAD
                    
                    // 구독 상태 텍스트
=======

                    // FREE 텍스트
>>>>>>> round_camera
                    Positioned(
                      left: 32,
                      top: 75,
                      child: Text(
<<<<<<< HEAD
                        _subscriptStatus,
=======
                        'FREE',
>>>>>>> round_camera
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.67,
                        ),
                      ),
                    ),
<<<<<<< HEAD
                    
                    // 트레킹 시작하기 버튼 (메인)
                    Positioned(
                      left: containerWidth * 0.2, // 146px 상대 크기
                      top: 234,
                      child: Container(
                        width: containerWidth * 0.57, // 392px 상대 크기
=======

                    // 트레킹 시작하기 버튼 (메인)
                    Positioned(
                      left: containerWidth * 0.2,
                      top: 234,
                      child: Container(
                        width: containerWidth * 0.57,
>>>>>>> round_camera
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
<<<<<<< HEAD
                              color: Colors.black.withOpacity(0.3),
=======
                              color: Colors.black.withOpacity(0.6),
>>>>>>> round_camera
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
<<<<<<< HEAD
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
                            } else {
                              _showFaceAuthRequiredDialog(context);
=======
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
>>>>>>> round_camera
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
<<<<<<< HEAD
                    
=======

>>>>>>> round_camera
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
<<<<<<< HEAD
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
=======
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
>>>>>>> round_camera
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
<<<<<<< HEAD
                                angle: 3.14159, // 180도 회전
                                child: Transform.scale(
                                  scaleY: -1, // Y축 반전
=======
                                angle: 3.14159,
                                child: Transform.scale(
                                  scaleY: -1,
>>>>>>> round_camera
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
<<<<<<< HEAD

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
=======
}

>>>>>>> round_camera
