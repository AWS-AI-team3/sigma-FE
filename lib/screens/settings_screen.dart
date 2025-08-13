import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Figma Node ID: 1-1338 (설정 페이지)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정값들
  String _leftClickGesture = '선택 안함';
  String _rightClickGesture = '오른손을 모두 펴고';
  String _wheelScrollGesture = 'text';
  String _recordStartGesture = 'text';
  String _recordStopGesture = 'text';
  
  bool _showMouseCursor = true;
  bool _useLeftHand = false;
  bool _showSkeleton = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 설정 페이지는 더 넓은 컨테이너 사용 (오버플로우 방지)
          final containerWidth = (screenWidth * 0.95).clamp(750.0, 950.0); // 최소 750px, 최대 950px
          final containerHeight = screenHeight * 0.9; // 높이도 조금 늘림
          
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
                    // 상단 제목과 Back 버튼
                    Positioned(
                      top: 40,
                      left: 45,
                      child: Row(
                        children: [
                          // 설정 아이콘
                          Container(
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.settings,
                              size: 35,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Setting 텍스트
                          Text(
                            'Setting',
                            style: GoogleFonts.roboto(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Back 버튼 (우상단)
                    Positioned(
                      top: 16,
                      right: 14,
                      child: Container(
                        width: 107,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6186FF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6186FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 구분선
                    Positioned(
                      top: 106,
                      left: 18,
                      child: Container(
                        width: containerWidth - 36, // 동적 너비
                        height: 1.4,
                        color: Colors.grey[300],
                      ),
                    ),
                    
                    // 손동작 섹션 (왼쪽)
                    Positioned(
                      top: 124,
                      left: containerWidth * 0.12, // 동적 위치
                      child: _buildGestureSection(),
                    ),
                    
                    // 화면 섹션 (오른쪽)
                    Positioned(
                      top: 121,
                      right: containerWidth * 0.12, // 동적 위치
                      child: _buildScreenSection(),
                    ),
                    
                    // 세로 구분선
                    Positioned(
                      top: 143,
                      left: containerWidth / 2, // 중앙에 배치
                      child: Container(
                        width: 1,
                        height: 292,
                        color: Colors.grey[300],
                      ),
                    ),
                    
                    // 저장하기 버튼 (하단 중앙)
                    Positioned(
                      bottom: 68,
                      left: (containerWidth - 95) / 2, // 중앙에 배치
                      child: Container(
                        width: 95,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AEFF),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('설정이 저장되었습니다'),
                                backgroundColor: Color(0xFF6186FF),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88AEFF),
                            foregroundColor: const Color(0xFF070F27),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            '저장하기',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF070F27),
                            ),
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

  Widget _buildGestureSection() {
    return Container(
      width: 280, // 너비 늘림
      child: Column(
        children: [
          // 손동작 헤더
          Container(
            width: 158,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFB6A0F3),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(12),
                right: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '손동작',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 좌클릭
          _buildGestureRow('좌클릭', _leftClickGesture, (value) {
            setState(() {
              _leftClickGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 우클릭
          _buildGestureRow('우클릭', _rightClickGesture, (value) {
            setState(() {
              _rightClickGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 휠스크롤
          _buildGestureRow('휠스크롤', _wheelScrollGesture, (value) {
            setState(() {
              _wheelScrollGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 녹음 시작
          _buildGestureRow('녹음 시작', _recordStartGesture, (value) {
            setState(() {
              _recordStartGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 녹음 중지
          _buildGestureRow('녹음 중지', _recordStopGesture, (value) {
            setState(() {
              _recordStopGesture = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildScreenSection() {
    return Container(
      width: 208,
      child: Column(
        children: [
          // 화면 헤더
          Container(
            width: 158,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFB6A0F3),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(12),
                right: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '화면',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 마우스 커서 표시
          _buildToggleRow('마우스 커서 표시', _showMouseCursor, (value) {
            setState(() {
              _showMouseCursor = value;
            });
          }),
          
          const SizedBox(height: 30),
          
          // 왼손 사용
          _buildToggleRow('왼손 사용', _useLeftHand, (value) {
            setState(() {
              _useLeftHand = value;
            });
          }),
          
          const SizedBox(height: 30),
          
          // 스켈레톤 표시
          _buildToggleRow('스켈레톤 표시', _showSkeleton, (value) {
            setState(() {
              _showSkeleton = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildGestureRow(String label, String value, Function(String) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 83,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF070F27),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 180, // 너비 늘림
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: value == '선택 안함' ? const Color(0xFFA0A0A0) : const Color(0xFF7DAEF3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.black,
              ),
              items: [
                '선택 안함',
                '오른손을 모두 펴고',
                'text',
              ].map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: item == '선택 안함' ? const Color(0xFF040F0F) : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF070F27),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 50,
          height: 22,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF313C73),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF7F7F7F),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
