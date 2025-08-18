import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/python_service.dart';
import '../services/user_service.dart';
import '../providers/settings_provider.dart';
import 'dart:typed_data';
import 'dart:async';

// Figma Node ID: 99-145 (트래킹 페이지)
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isCameraEnabled = true; // 기본적으로 카메라가 켜진 상태
  bool _isMicEnabled = false; // 기본적으로 마이크가 꺼진 상태
  StreamSubscription<String>? _gestureSubscription;
  StreamSubscription<Map<String, dynamic>>? _transcriptSubscription;
  StreamSubscription<Map<String, dynamic>>? _commandSubscription;
  
  String _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
  String _currentTranscript = '';
  bool _isTranscribing = false;
  bool _hasTranscript = false;
  bool _isCommandProcessing = false;

  // 사용자 정보
  String _userName = 'AWS님';
  String? _profileUrl;
  String _subscriptStatus = 'FREE';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadMotionSettings();
    _initializeServices();
    _startGestureListening();
    _startTranscriptListening();
    _startCommandListening();
  }

  Future<void> _loadMotionSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.loadMotionSettingsFromServer();
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
  
  void _initializeServices() {
    // Python에서 모든 오디오 처리를 하므로 별도 초기화 없음
  }

  @override
  void dispose() {
    // Stop subscriptions
    _gestureSubscription?.cancel();
    _transcriptSubscription?.cancel();
    _commandSubscription?.cancel();
    
    // Stop Python processes when leaving the tracking screen
    print('TrackingScreen dispose: cleaning up Python processes...');
    
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
  }

  void _toggleMic() async {
    if (_isMicEnabled) {
      // 마이크가 켜져있으면 녹음 중지 (제스처 recording_stop과 동일하게 처리)
      setState(() {
        _isMicEnabled = false;
        _isTranscribing = false;
      });
      
      // Python에 녹음 중지 신호 전송
      PythonService.sendCommand('manual_recording_stop');
      print('Manual recording stopped via mic button');
    } else {
      // 마이크가 꺼져있으면 녹음 시작 (제스처 recording_start와 동일하게 처리)
      setState(() {
        _isMicEnabled = true;
        _isTranscribing = true;
        _hasTranscript = false; // 버튼 비활성화
        _currentTranscript = ''; // 텍스트 초기화
        _currentSubtitle = "음성을 인식하고 있습니다...";
      });
      
      // Python에 녹음 시작 신호 전송
      PythonService.sendCommand('manual_recording_start');
      print('Manual recording started via mic button');
    }
  }

  void _startGestureListening() {
    _gestureSubscription = PythonService.gestureStream.listen((gesture) {
      if (gesture == 'recording_start') {
        // 엄지+약지 pinch 시작 - UI 상태 초기화
        setState(() {
          _isMicEnabled = true;
          _isTranscribing = true;
          _hasTranscript = false; // 버튼 비활성화
          _currentTranscript = ''; // 텍스트 초기화
          _currentSubtitle = "음성을 인식하고 있습니다...";
        });
      } else if (gesture == 'recording_stop') {
        // 엄지+약지 pinch 중지 - UI 상태만 업데이트
        setState(() {
          _isMicEnabled = false;
          _isTranscribing = false;
          // recording_stop에서는 transcript 체크하지 않음 - transcript 수신 시 처리
          print('Recording stopped, waiting for transcript...');
        });
      }
      // recording_hold은 녹음 상태 유지이므로 별도 처리 불필요
    });
  }

  void _startTranscriptListening() {
    _transcriptSubscription = PythonService.transcriptStream.listen((transcriptData) {
      final text = transcriptData['text'] as String? ?? '';
      final isPartial = transcriptData['is_partial'] as bool? ?? false;
      
      print('Transcript stream received: "$text", isPartial: $isPartial');
      setState(() {
        if (isPartial) {
          // 부분 결과는 임시로 표시 (회색 또는 다른 스타일)
          _currentSubtitle = '$text...';
          _isTranscribing = true;
          print('Partial transcript displayed: "$text"');
        } else {
          // 최종 결과
          _currentTranscript = text;
          _isTranscribing = false;
          
          if (text.isNotEmpty) {
            // 텍스트가 있으면 버튼 활성화
            _hasTranscript = true;
            _currentSubtitle = text;
            print('Final transcript received: "$text", hasTranscript: $_hasTranscript, isTranscribing: $_isTranscribing');
          } else {
            // 텍스트가 없으면 취소하기와 동일하게 처리
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
      // 즉시 UI 상태 업데이트
      setState(() {
        _hasTranscript = false;
        _currentTranscript = '';
        _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
      });
      
      // Python에 clear 명령 전송
      PythonService.sendCommand('clear_transcript');
      
      print('Transcript cleared: hasTranscript=$_hasTranscript, transcript="$_currentTranscript"');
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
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
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
                      top: 25,
                      left: 25,
                      child: Container(
                        width: 345,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6186FF),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 프로필 아이콘 배경 원
                            Positioned(
                              left: 14,
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
                              left: 9,
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
                              left: 66,
                              top: 13,
                              child: Text(
                                _userName,
                                style: GoogleFonts.roboto(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            
                            // 컨트롤 패널 (오른쪽)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 150,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB2CBFF),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: const Color(0xFF5356FF),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 카메라 토글 아이콘
                                    GestureDetector(
                                      onTap: _toggleCamera,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: 32,
                                          color: _isCameraEnabled ? Colors.red : Colors.black,
                                        ),
                                      ),
                                    ),
                                    // 마이크 아이콘
                                    GestureDetector(
                                      onTap: _toggleMic,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          boxShadow: [],
                                        ),
                                        child: Icon(
                                          Icons.mic,
                                          size: 32,
                                          color: _isMicEnabled ? Colors.red : Colors.black,
                                        ),
                                      ),
                                    ),
                                    // 닫기 아이콘
                                    GestureDetector(
                                      onTap: () async {
                                        // 카메라 끄기
                                        setState(() {
                                          _isCameraEnabled = false;
                                          _isMicEnabled = false;
                                          _isTranscribing = false;
                                          _currentSubtitle = '엄지와 약지를 붙이면 음성인식이 시작됩니다.';
                                        });
                                        
                                        // 스트림 구독 정리
                                        _gestureSubscription?.cancel();
                                        _transcriptSubscription?.cancel();
                                        _commandSubscription?.cancel();
                                        
                                        // Python 프로세스 완전 종료
                                        print('Window is closing, cleaning up Python processes...');
                                        await PythonService.cleanup();
                                        
                                        // main_dashboard_screen으로 이동
                                        if (mounted) Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 28,
                                          color: Colors.black,
                                        ),
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
                    
                    // 구독 상태 텍스트
                    Positioned(
                      left: 30,
                      top: 80,
                      child: Text(
                        _subscriptStatus,
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    
                    // 웹캠 카메라 영역 (오른쪽, FREE와 같은 높이)
                    Positioned(
                      right: 30,
                      top: 90,
                      child: Container(
                        width: 180,
                        height: 135,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          border: Border.all(
                            color: const Color(0xFF6186FF),
                            width: 1,
                          ),
                        ),
                        child: _isCameraEnabled
                            ? StreamBuilder<Uint8List>(
                                stream: PythonService.cameraStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return ClipRect(
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.videocam,
                                            size: 40,
                                            color: Color(0xFF6186FF),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '카메라 연결중...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B6B6B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam_off,
                                      size: 40,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '카메라 꺼짐',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    
                    // 명령 도움말 메뉴 (하단 안내 패널 위)
                    Positioned(
                      left: 30,
                      bottom: 160,
                      child: Container(
                        width: containerWidth * 0.85,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF6186FF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 제목
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                '명령 도움말',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B6B6B),
                                  height: 1.0,
                                ),
                              ),
                            ),
                            // 명령 리스트
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(1),
                                children: [
                                  _buildCommandItem(
                                    icon: Icons.verified_outlined,
                                    text: "검색하기 ('브라우저 이름'에서 '찾고싶은것' 찾아줘",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 하단 안내 패널
                    Positioned(
                      left: 30,
                      bottom: 30,
                      child: Container(
                        width: containerWidth * 0.85,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            // 마이크 아이콘
                            GestureDetector(
                              onTap: _toggleMic,
                              child: Container(
                                margin: const EdgeInsets.only(left: 5, top: 15, bottom: 15),
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                  ],
                                ),
                                child: Icon(
                                  Icons.mic,
                                  size: 32,
                                  color: _isMicEnabled ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                            // 안내 텍스트 / 실시간 자막
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(left: 0, right: 10),
                                child: Text(
                                  _currentSubtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _isTranscribing ? Colors.blue : Colors.black,
                                    height: 1.2,
                                    fontStyle: _isTranscribing ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                            // 버튼들 (세로로 배치)
                            Container(
                              margin: const EdgeInsets.only(right: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 보내기 버튼
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: (_hasTranscript && !_isCommandProcessing) ? _sendCommand : null,
                                      icon: Icon(
                                        _isCommandProcessing ? Icons.hourglass_empty : Icons.send,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isCommandProcessing ? '처리중' : '보내기',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: () {
                                          final shouldBeActive = (_hasTranscript && !_isCommandProcessing);
                                          print('Button color logic: hasTranscript=$_hasTranscript, processing=$_isCommandProcessing, shouldBeActive=$shouldBeActive');
                                          return shouldBeActive
                                              ? const Color(0xFF6186FF) 
                                              : const Color(0xFF9E9E9E);
                                        }(),
                                        minimumSize: const Size(70, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 취소하기 버튼
                                  ElevatedButton.icon(
                                    onPressed: (_hasTranscript && !_isCommandProcessing) ? _clearTranscript : null,
                                    icon: const Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      '취소하기',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (_hasTranscript && !_isCommandProcessing) 
                                          ? const Color(0xFFFF5252) 
                                          : const Color(0xFF9E9E9E),
                                      minimumSize: const Size(70, 32),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _buildCommandItem({required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B6B6B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6B6B),
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }
}