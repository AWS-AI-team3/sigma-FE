import 'package:flutter/material.dart';

class ConfirmationDialogScreen extends StatefulWidget {
  final String command;
  final String description;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialogScreen({
    Key? key,
    required this.command,
    required this.description,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ConfirmationDialogScreen> createState() => _ConfirmationDialogScreenState();
}

class _ConfirmationDialogScreenState extends State<ConfirmationDialogScreen> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[300], // 윈도우 배경색
      body: Stack(
        children: [
          // 상단 제어 패널
          _buildTopControlPanel(),
          
          // 중앙 확인 대화상자
          Center(
            child: _buildConfirmationDialog(),
          ),
          
          // 우측 상단 비디오 화면 (선택사항)
          Positioned(
            right: 20,
            top: 50,
            child: _buildVideoFrame(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControlPanel() {
    return Positioned(
      left: 43,
      top: 39,
      child: Container(
        width: 216,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFB2CBFF),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF0400FF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0400FF).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(Icons.videocam, () {}),
            _buildControlButton(Icons.mic, () {}),
            _buildControlButton(Icons.close, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    return Container(
      width: 737,
      height: 353,
      decoration: BoxDecoration(
        color: const Color(0xFFDFE0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          const SizedBox(height: 19),
          
          // 상단 제목과 알림 아이콘
          Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 97,
                height: 83,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications,
                  size: 45,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '요청을 수행 하시겠습니까?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 26),
          
          // 명령어 정보 박스
          _buildCommandInfoBox(),
          
          const Spacer(),
          
          // 하단 버튼들
          _buildActionButtons(),
          
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildCommandInfoBox() {
    return Container(
      width: 603,
      height: 173,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.command,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 네 버튼
        GestureDetector(
          onTap: widget.onConfirm,
          child: Container(
            width: 163,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF537EFF),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '네',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 85),
        
        // 아니요 버튼
        GestureDetector(
          onTap: widget.onCancel,
          child: Container(
            width: 163,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '아니요',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoFrame() {
    return Container(
      width: 266,
      height: 232,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        border: Border.all(color: const Color(0xFF070202), width: 3),
      ),
      child: Stack(
        children: [
          // 비디오 화면 (현재는 플레이스홀더)
          Container(
            color: Colors.grey[600],
            child: const Center(
              child: Icon(
                Icons.videocam,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          
          // 삭제 버튼
          Positioned(
            right: 8,
            top: 5,
            child: GestureDetector(
              onTap: () {
                // 비디오 화면 닫기
              },
              child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11.5),
                ),
                child: const Icon(
                  Icons.delete,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}