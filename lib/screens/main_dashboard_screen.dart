import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'tracking_screen.dart';
import 'face_registration_screen.dart';
import '../services/python_service.dart';
import '../services/face_auth_service.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import '../providers/settings_provider.dart';

// Figma Node ID: 12-737 (통합 대시보드)
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  String _userName = '박제원';
  String? _profileUrl;
  String _subscriptStatus = 'free 요금제';
  
  final List<String> gestureOptions = [
    '엄지와 검지를',
    '엄지와 중지를',
    '엄지와 새끼를',
    '선택 안함',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // 설정 화면이 로드될 때 서버에서 모션 설정 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.loadMotionSettingsFromServer();
    });
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await UserService.getUserInfo();
    if (userInfo != null && userInfo['sucess'] == true) {
      final data = userInfo['data'];
      if (mounted) {
        setState(() {
          _userName = data['userName'] ?? '박제원';
          _profileUrl = data['profileUrl'];
          String status = data['subscriptStatus'] ?? 'free';
          _subscriptStatus = status.endsWith('요금제') ? status : '$status 요금제';
        });
      }
    }
  }

  // 설정 변경 시 실시간으로 적용하는 함수
  Future<void> _applySettingChange(Function updateFunction) async {
    updateFunction();
    
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    try {
      // 설정을 서버에 저장
      await settingsProvider.saveAllSettings();
      
      // Python 프로세스가 실행 중인 경우에만 재시작
      if (PythonService.isTracking) {
        print('트래킹 중이므로 Python 프로세스를 재시작합니다.');
        await PythonService.cleanup();
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 새로운 설정으로 다시 시작
        await PythonService.startHandTracking(
          showSkeleton: settingsProvider.showSkeleton
        );
      } else {
        print('트래킹이 시작되지 않았으므로 설정만 저장합니다.');
      }
    } catch (e) {
      print('설정 적용 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFE8E8E8),
          body: Row(
            children: [
              // 좌측 패널 (사용자 정보 및 설정)
              Container(
                width: 360,
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 로그아웃 버튼
                      GestureDetector(
                        onTap: () async {
                          await GoogleAuthService.logout();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF5381F6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '로그아웃',
                              style: const TextStyle(
                                fontFamily: 'AppleSDGothicNeo',
                                color: Color(0xFF5381F6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 사용자 정보 컨테이너
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: _profileUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, color: Colors.white, size: 30);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontFamily: 'AppleSDGothicNeo',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _subscriptStatus,
                                  style: TextStyle(
                                    fontFamily: 'AppleSDGothicNeo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 컨트롤 아이콘들 컨테이너
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            _buildControlIcon('assets/images/camera_gray.png', 24, 16),
                            const SizedBox(width: 77),
                            _buildControlIcon('assets/images/mic.png', 16, 22),
                            const SizedBox(width: 88),
                            _buildControlIcon('assets/images/x_logo.png', 13, 13),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 손동작 섹션 컨테이너
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '손동작',
                              style: const TextStyle(
                                fontFamily: 'AppleSDGothicNeo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // 가로선
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            _buildGestureDropdownRow(
                              '좌클릭',
                              settingsProvider.leftClickValue,
                              (value) {
                                _applySettingChange(() => settingsProvider.setLeftClickValue(value));
                              },
                            ),
                            
                            const SizedBox(height: 15),
                            
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            _buildGestureDropdownRow(
                              '우클릭',
                              settingsProvider.rightClickValue,
                              (value) {
                                _applySettingChange(() => settingsProvider.setRightClickValue(value));
                              },
                            ),
                            
                            const SizedBox(height: 15),
                            
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            _buildGestureDropdownRow(
                              '붙여넣기',
                              settingsProvider.wheelScrollValue,
                              (value) {
                                _applySettingChange(() => settingsProvider.setWheelScrollValue(value));
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 화면 섹션 컨테이너
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '화면',
                              style: const TextStyle(
                                fontFamily: 'AppleSDGothicNeo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // 가로선
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '스켈레톤 표시',
                                  style: const TextStyle(
                                    fontFamily: 'AppleSDGothicNeo',
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                Switch(
                                  value: settingsProvider.showSkeleton,
                                  onChanged: (value) {
                                    _applySettingChange(() => settingsProvider.setShowSkeleton(value));
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF5381F6),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                ),
              ),
              
              // 세로 구분선
              Container(
                width: 1,
                color: Colors.grey[300],
              ),
              
              // 우측 패널 (트래킹 시작하기 버튼)
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      // 상단 tracking.png 컴포넌트
                      Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        child: Image.asset(
                          'assets/images/tracking.png',
                          width: 280,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 280,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  '트래킹',
                                  style: TextStyle(
                                    fontFamily: 'AppleSDGothicNeo',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // 트래킹 시작하기 버튼
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
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
                                
                                print('Starting tracking with showSkeleton: \${settingsProvider.showSkeleton}');
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
                                      backgroundColor: Color(0xFF5381F6),
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
                            child: Image.asset(
                              'assets/images/tracking_start.png',
                              width: 280,
                              height: 60,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 280,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF5381F6), Color(0xFF677BFF)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '트래킹 시작하기',
                                      style: const TextStyle(
                                        fontFamily: 'AppleSDGothicNeo',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlIcon(String imagePath, double width, double height) {
    return GestureDetector(
      onTap: () {
        // 버튼 클릭 기능 추가 가능
      },
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error,
              color: Colors.grey,
              size: (width < height ? width : height) * 0.6,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGestureDropdownRow(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'AppleSDGothicNeo',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Container(
          width: 180,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'AppleSDGothicNeo',
                fontSize: 14,
                color: Colors.black,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: gestureOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'AppleSDGothicNeo',
                      fontSize: 14,
                      color: option == '선택 안함' ? Colors.grey : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
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
                      style: const TextStyle(
                        fontFamily: 'AppleSDGothicNeo',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '얼굴 인증을 먼저 완료해주세요.',
                      style: const TextStyle(
                        fontFamily: 'AppleSDGothicNeo',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
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
                              style: const TextStyle(
                                fontFamily: 'AppleSDGothicNeo',
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
                              style: const TextStyle(
                                fontFamily: 'AppleSDGothicNeo',
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

