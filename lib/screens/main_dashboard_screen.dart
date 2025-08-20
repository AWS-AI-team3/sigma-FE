import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'face_registration_screen.dart';
import '../services/python_service.dart';
import '../services/face_auth_service.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import '../providers/settings_provider.dart';
import 'dart:async';
import 'dart:typed_data';

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
  
  // 트래킹 상태 관리
  bool _isTrackingMode = false;
  bool _isCameraEnabled = true;
  bool _isMicEnabled = false;
  bool _isTranscribing = false;
  bool _hasTranscript = false;
  String _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
  String _currentTranscript = '';
  bool _isCommandProcessing = false;
  
  // 스트림 구독
  StreamSubscription<String>? _gestureSubscription;
  StreamSubscription<Map<String, dynamic>>? _transcriptSubscription;
  StreamSubscription<Map<String, dynamic>>? _commandSubscription;
  
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
  
  @override
  void dispose() {
    // Stop subscriptions
    _gestureSubscription?.cancel();
    _transcriptSubscription?.cancel();
    _commandSubscription?.cancel();
    
    super.dispose();
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

  void _startGestureListening() {
    _gestureSubscription = PythonService.gestureStream.listen((gesture) {
      if (gesture == 'recording_start') {
        setState(() {
          _isMicEnabled = true;
          _isTranscribing = true;
          _hasTranscript = false;
          _currentTranscript = '';
          _currentSubtitle = "음성을 인식하고 있습니다...";
        });
      } else if (gesture == 'recording_stop') {
        setState(() {
          _isMicEnabled = false;
          _isTranscribing = false;
          // recording_stop 시점에서 transcript가 없으면 초기 상태로 돌아감
          if (!_hasTranscript) {
            _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
          }
          print('Recording stopped, waiting for transcript...');
        });
      }
    });
  }

  void _startTranscriptListening() {
    _transcriptSubscription = PythonService.transcriptStream.listen((transcriptData) {
      final text = transcriptData['text'] as String? ?? '';
      final isPartial = transcriptData['is_partial'] as bool? ?? false;
      
      print('Transcript stream received: "$text", isPartial: $isPartial');
      setState(() {
        if (isPartial) {
          _currentSubtitle = '$text...';
          _isTranscribing = true;
          print('Partial transcript displayed: "$text"');
        } else {
          _currentTranscript = text;
          _isTranscribing = false;
          
          if (text.isNotEmpty) {
            _hasTranscript = true;
            _currentSubtitle = text;
            print('Final transcript received: "$text", hasTranscript: $_hasTranscript, isTranscribing: $_isTranscribing');
          } else {
            _hasTranscript = false;
            _currentTranscript = '';
            _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
            print('Empty transcript received - auto clearing. hasTranscript: $_hasTranscript');
          }
        }
      });
    });
  }

  void _startCommandListening() {
    _commandSubscription = PythonService.commandStream.listen((commandData) {
      final type = commandData['type'] as String? ?? '';
      
      setState(() {
        if (type == 'command_request') {
          final status = commandData['status'] as String? ?? '';
          if (status == 'sent') {
            _isCommandProcessing = true;
            _currentSubtitle = '명령어 변환 중...';
          } else if (status == 'failed') {
            _isCommandProcessing = false;
            _currentSubtitle = '명령어 변환 실패';
          }
        } else if (type == 'command_response') {
          final success = commandData['success'] as bool? ?? false;
          if (success) {
            final command = commandData['command'] as String? ?? '';
            _currentSubtitle = '명령어 실행 중: $command';
          } else {
            _isCommandProcessing = false;
            final message = commandData['message'] as String? ?? '명령어 생성 실패';
            _currentSubtitle = '오류: $message';
          }
        } else if (type == 'command_execution') {
          final status = commandData['status'] as String? ?? '';
          if (status == 'success') {
            _isCommandProcessing = false;
            _currentSubtitle = '명령어 실행 완료';
            _hasTranscript = false;
            _currentTranscript = '';
          } else if (status == 'error' || status == 'timeout' || status == 'failed') {
            _isCommandProcessing = false;
            final error = commandData['error'] as String? ?? '실행 실패';
            _currentSubtitle = '실행 오류: $error';
          }
        } else if (type == 'transcript_cleared') {
          _hasTranscript = false;
          _currentTranscript = '';
          _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
        }
      });
    });
  }
  
  void _sendCommand() {
    print('Send command pressed: hasTranscript=$_hasTranscript, transcript="$_currentTranscript", processing=$_isCommandProcessing');
    if (_hasTranscript && _currentTranscript.isNotEmpty && !_isCommandProcessing) {
      PythonService.sendCommand('send_command', _currentTranscript);
    }
  }
  
  void _clearTranscript() {
    if (!_isCommandProcessing) {
      setState(() {
        _hasTranscript = false;
        _currentTranscript = '';
        _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
      });
      
      PythonService.sendCommand('clear_transcript');
      
      print('Transcript cleared: hasTranscript=$_hasTranscript, transcript="$_currentTranscript"');
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
          body: Stack(
            children: [
              Row(
                children: [
              // 좌측 패널 (사용자 정보 및 설정)
              Container(
                width: 360,
                color: const Color(0xFFF2F2F7),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF5381F6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Transform.translate(
                              offset: const Offset(0, 2),
                              child: Text(
                                '로그아웃',
                                style: const TextStyle(
                                  fontFamily: 'AppleSDGothicNeo',
                                  color: Color(0xFF5381F6),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w200,
                                ),
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
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isCameraEnabled = !_isCameraEnabled;
                                });
                              },
                              child: Icon(
                                Icons.videocam,
                                size: 24,
                                color: (_isTrackingMode && _isCameraEnabled) ? const Color(0xFF34BF49) : const Color(0xFFA2A2A2),
                              ),
                            ),
                            const SizedBox(width: 77),
                            GestureDetector(
                              onTap: () async {
                                if (_isMicEnabled) {
                                  setState(() {
                                    _isMicEnabled = false;
                                    _isTranscribing = false;
                                  });
                                  
                                  PythonService.sendCommand('manual_recording_stop');
                                  print('Manual recording stopped via mic button');
                                } else {
                                  setState(() {
                                    _isMicEnabled = true;
                                    _isTranscribing = true;
                                    _hasTranscript = false;
                                    _currentTranscript = '';
                                    _currentSubtitle = "음성을 인식하고 있습니다...";
                                  });
                                  
                                  PythonService.sendCommand('manual_recording_start');
                                  print('Manual recording started via mic button');
                                }
                              },
                              child: Icon(
                                Icons.mic,
                                size: 22,
                                color: _isMicEnabled ? Colors.red : const Color(0xFFA2A2A2),
                              ),
                            ),
                            const SizedBox(width: 88),
                            GestureDetector(
                              onTap: () async {
                                // 스트림 구독 정리
                                _gestureSubscription?.cancel();
                                _transcriptSubscription?.cancel();
                                _commandSubscription?.cancel();
                                
                                await PythonService.cleanup();
                                setState(() {
                                  _isTrackingMode = false;
                                  _isCameraEnabled = false;
                                  _isMicEnabled = false;
                                  _isTranscribing = false;
                                  _hasTranscript = false;
                                  _currentTranscript = '';
                                  _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
                                });
                              },
                              child: Image.asset(
                                'assets/images/x_logo.png',
                                width: 13,
                                height: 13,
                              ),
                            ),
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
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // 가로선
                            Transform.translate(
                              offset: const Offset(-16, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 1,
                                color: const Color(0xFFE6E5E5),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            _buildGestureDropdownRow(
                              '좌클릭',
                              settingsProvider.leftClickValue,
                              (value) {
                                _applySettingChange(() => settingsProvider.setLeftClickValue(value));
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Transform.translate(
                              offset: const Offset(-16, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 1,
                                color: const Color(0xFFE6E5E5),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildGestureDropdownRow(
                              '우클릭',
                              settingsProvider.rightClickValue,
                              (value) {
                                _applySettingChange(() => settingsProvider.setRightClickValue(value));
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Transform.translate(
                              offset: const Offset(-16, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 1,
                                color: const Color(0xFFE6E5E5),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
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
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // 가로선
                            Transform.translate(
                              offset: const Offset(-16, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 1,
                                color: const Color(0xFFE6E5E5),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '스켈레톤 표시',
                                  style: const TextStyle(
                                    fontFamily: 'AppleSDGothicNeo',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _applySettingChange(() => settingsProvider.setShowSkeleton(!settingsProvider.showSkeleton));
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 26,
                                    decoration: ShapeDecoration(
                                      gradient: settingsProvider.showSkeleton 
                                          ? const LinearGradient(
                                              begin: Alignment(0.00, 0.22),
                                              end: Alignment(0.97, 1.00),
                                              colors: [Color(0xFF578EF6), Color(0xFF496BF5), Color(0xFF383AF4)],
                                            )
                                          : null,
                                      color: settingsProvider.showSkeleton ? null : Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(milliseconds: 200),
                                      alignment: settingsProvider.showSkeleton ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        margin: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
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
              
              // 세로 구분선
              Container(
                width: 1,
                color: Colors.grey[300],
              ),
              
              // 우측 패널
              Expanded(
                flex: 1,
                child: _isTrackingMode ? _buildTrackingLayout() : _buildInitialLayout(),
              ),
                ],
              ),
          
              // SIGMA 로고와 텍스트 (절대 위치)
              Positioned(
                bottom: 12,
                left: 287,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/sigma_logo_grey.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 5),
                    Image.asset(
                      'assets/images/sigma_text_grey.png',
                      width: 40,
                      height: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialLayout() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // 트래킹 아이콘
          Positioned(
            top: 172,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/tracking.png',
                width: 162,
                height: 162,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // 트래킹 제목
          Positioned(
            top: 362, // 172 + 162 + 28
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                '트래킹',
                style: TextStyle(
                  fontFamily: 'AppleSDGothicNeo',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          
          // 설명 텍스트
          Positioned(
            top: 404, // 362 + 24 + 18
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 400,
                child: const Text(
                  '카메라를 통해 손가락 및 행동을 추적하여 컴퓨터를 조작하도록 합니다.\n또한, 마이크를 통해 명령을 실행할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'AppleSDGothicNeo',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7A7A7A),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
                                    
          // 트래킹 시작하기 버튼
          Positioned(
            top: 559,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
                      setState(() {
                        _isTrackingMode = true;
                        _isCameraEnabled = true; // 트래킹 시작 시 카메라 자동 켜기
                      });
                      
                      // 트래킹 시작 시 스트림 리스닝 시작
                      _startGestureListening();
                      _startTranscriptListening();
                      _startCommandListening();
                      
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
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/Rectangle_grey.png',
                      width: 258,
                      height: 68,
                      fit: BoxFit.fill,
                    ),
                    Container(
                      width: 258,
                      height: 68,
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment(0.00, 0.22),
                            end: Alignment(0.97, 1.00),
                            colors: [Color(0xFF578EF6), Color(0xFF496BF5), Color(0xFF383AF4)],
                          ).createShader(bounds),
                          child: const Text(
                            '트래킹 시작',
                            style: TextStyle(
                              fontFamily: 'AppleSDGothicNeo',
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Widget _buildTrackingLayout() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 카메라 영역
            Container(
              width: 378,
              height: 378,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _isCameraEnabled
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: StreamBuilder<Uint8List>(
                        stream: PythonService.cameraStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRect(
                              child: Image.memory(
                                snapshot.data!,
                                width: 378,
                                height: 378,
                                fit: BoxFit.cover,  // Changed from fill to cover for better aspect ratio
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.low,  // Added for better performance
                                cacheWidth: 378,  // Cache at display size for memory efficiency
                                cacheHeight: 378,
                              ),
                            );
                          } else {
                            return Image.asset(
                              'assets/images/camera_area.png',
                              width: 378,
                              height: 378,
                              fit: BoxFit.cover,
                            );
                          }
                        },
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/camera_area.png',
                            width: 378,
                            height: 378,
                            fit: BoxFit.cover,
                          ),
                          Center(
                            child: Icon(
                              Icons.videocam,
                              size: 140,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            const SizedBox(height: 30),

            // 명령 도움말
            Container(
              width: 378,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D5381F6), // #5381F64D (30% opacity)
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF578EF6), Color(0xFF496BF5), Color(0xFF383AF4)],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28), // 30 - 2 = 28
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: const Text(
                        '명령 도움말',
                        style: TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                        children: [
                          _buildCommandHelpItem('• 유튜브 열어줘'),
                          _buildCommandHelpItem('• 바탕화면에 텍스트 파일 만들고 열어줘'),
                          _buildCommandHelpItem('• 가장 최근에 수정했던 파일 열어줘'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // 음성 실시간 자막 영역
            Container(
              width: 378,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D8D8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  // 마이크 아이콘
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: Icon(
                      Icons.mic,
                      size: 24,
                      color: _isMicEnabled ? Colors.red : Colors.grey[700],
                    ),
                  ),
                  
                  // 자막 텍스트
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        _currentSubtitle,
                        style: TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _isTranscribing ? Colors.blue : Colors.grey[700],
                          fontStyle: _isTranscribing ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                  
                  // 보내기 및 취소하기 버튼 (세로 배치)
                  Container(
                    margin: const EdgeInsets.only(right: 29),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 보내기 버튼
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            onPressed: (_hasTranscript && !_isCommandProcessing) ? _sendCommand : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_hasTranscript && !_isCommandProcessing) 
                                  ? Colors.transparent
                                  : const Color(0xFFBDBDBD),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(70, 25),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Container(
                              decoration: (_hasTranscript && !_isCommandProcessing) 
                                  ? const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(0.00, 0.22),
                                        end: Alignment(0.97, 1.00),
                                        colors: [Color(0xFF578EF6), Color(0xFF496BF5), Color(0xFF383AF4)],
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(30)),
                                    )
                                  : null,
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_isCommandProcessing) ...[
                                      Icon(
                                        Icons.send,
                                        size: 12,
                                        color: (_hasTranscript && !_isCommandProcessing) 
                                            ? Colors.white 
                                            : const Color(0xFF7A7A7A),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      _isCommandProcessing ? '처리중' : '보내기',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        color: (_hasTranscript && !_isCommandProcessing) 
                                            ? Colors.white 
                                            : const Color(0xFF7A7A7A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 취소하기 버튼
                        ElevatedButton(
                          onPressed: (_hasTranscript && !_isCommandProcessing) ? _clearTranscript : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_hasTranscript && !_isCommandProcessing) 
                                ? const Color(0xFFFF5252) 
                                : const Color(0xFFBDBDBD),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(70, 25),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close,
                                size: 12,
                                color: (_hasTranscript && !_isCommandProcessing) 
                                    ? Colors.white 
                                    : const Color(0xFF7A7A7A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '취소하기',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: (_hasTranscript && !_isCommandProcessing) 
                                      ? Colors.white 
                                      : const Color(0xFF7A7A7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHelpItem(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'AppleSDGothicNeo',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF7A7A7A),
        ),
      ),
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
              color: const Color(0xFFA2A2A2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error,
              color: const Color(0xFFA2A2A2),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Container(
          width: 156,
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCECCCC), width: 1),
            borderRadius: BorderRadius.circular(7),
            color: const Color(0xFFFFFFFF),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'AppleSDGothicNeo',
                fontWeight: FontWeight.w400,
                fontSize: 10,
                color: Colors.black,
              ),
              icon: Transform.translate(
                offset: const Offset(0, -2),
                child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF827F7F)),
              ),
              items: gestureOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'AppleSDGothicNeo',
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
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

