import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigma_flutter_ui/services/python_service.dart';
import 'dart:typed_data';

// Figma Node ID: 99-145 (트래킹 페이지)
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isCameraEnabled = true; // 기본적으로 카메라가 켜진 상태

  @override
  void dispose() {
    // Stop Python processes when leaving the tracking screen
    PythonService.stopHandTracking();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    
    if (!_isCameraEnabled) {
      // 카메라 끄기 - Python에서 카메라 스트림 중지
      PythonService.stopCameraStream();
    } else {
      // 카메라 켜기 - Python에서 카메라 스트림 재시작
      PythonService.startCameraStream();
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
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 50,
                                  color: Color(0xFF0D0D11),
                                ),
                              ),
                            ),
                            
                            // AWS님 텍스트
                            Positioned(
                              left: 66,
                              top: 13,
                              child: Text(
                                'AWS님',
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
                                        width: 39,
                                        height: 39,
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
                                    Container(
                                      width: 39,
                                      height: 39,
                                      decoration: BoxDecoration(
                                        boxShadow: [],
                                      ),
                                      child: const Icon(
                                        Icons.mic,
                                        size: 32,
                                        color: Colors.black,
                                      ),
                                    ),
                                    // 닫기 아이콘
                                    GestureDetector(
                                      onTap: () async {
                                        await PythonService.stopHandTracking();
                                        if (mounted) Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 33,
                                        height: 33,
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
                    
                    // FREE 텍스트
                    Positioned(
                      left: 30,
                      top: 80,
                      child: Text(
                        'FREE',
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
                            Container(
                              margin: const EdgeInsets.only(left: 20, top: 15, bottom: 15),
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                boxShadow: [
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                            // 안내 텍스트
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(left: 15, right: 15),
                                child: Text(
                                  '방금 복사한 사진을 쳇 지피티한테 보내고 위 사진에 나와있는 에러를 어떻게 해결 하는지 물어봐줘.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                    height: 1.2,
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