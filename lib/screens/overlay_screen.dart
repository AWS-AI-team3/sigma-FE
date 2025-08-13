import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:io';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> with WindowListener {
  WebSocketChannel? _channel;
  Map<String, dynamic>? _handData;
  bool _isConnected = false;
  String _connectionStatus = '연결 중...';

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setupOverlayWindow();
    _connectToBackend();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _channel?.sink.close();
    super.dispose();
  }

  // 오버레이 창 설정
  Future<void> _setupOverlayWindow() async {
    // 전체화면으로 설정
    await windowManager.setFullScreen(true);
    
    // 항상 위에 표시
    await windowManager.setAlwaysOnTop(true);
    
    // 마우스 이벤트 무시 (투명하게 동작)
    await windowManager.setIgnoreMouseEvents(true);
    
    // 투명 배경
    await windowManager.setBackgroundColor(Colors.transparent);
    
    // 창 경계 없음
    await windowManager.setAsFrameless();
    
    print('✅ 오버레이 창 설정 완료');
  }

  // Python 백엔드에 연결
  void _connectToBackend() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/hand-tracking'),
      );

      _channel!.stream.listen(
        (data) {
          final jsonData = json.decode(data);
          setState(() {
            _handData = jsonData;
            _isConnected = true;
            _connectionStatus = '연결됨';
          });
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _connectionStatus = '연결 오류: $error';
          });
          print('❌ WebSocket 오류: $error');
          
          // 재연결 시도
          Future.delayed(const Duration(seconds: 2), () {
            _connectToBackend();
          });
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _connectionStatus = '연결 끊김';
          });
          print('🔌 WebSocket 연결 종료');
        },
      );
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = '연결 실패: $e';
      });
      print('❌ WebSocket 연결 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 손가락 오버레이 (전체화면)
          if (_handData != null && _handData!['hands'] != null)
            ..._buildHandOverlays(),
          
          // 상태 표시 (오른쪽 상단)
          Positioned(
            top: 20,
            right: 20,
            child: _buildStatusIndicator(),
          ),
          
          // 종료 버튼 (왼쪽 상단)
          Positioned(
            top: 20,
            left: 20,
            child: _buildExitButton(),
          ),
        ],
      ),
    );
  }

  // 손가락 오버레이들 생성
  List<Widget> _buildHandOverlays() {
    List<Widget> overlays = [];
    
    for (var hand in _handData!['hands']) {
      if (hand['fingertips'] != null) {
        var fingertips = hand['fingertips'];
        
        // 각 손가락 끝에 점 그리기
        for (var fingerName in ['thumb', 'index', 'middle', 'ring', 'pinky']) {
          if (fingertips[fingerName] != null) {
            var finger = fingertips[fingerName];
            overlays.add(_buildFingerDot(
              x: finger['x'].toDouble(),
              y: finger['y'].toDouble(),
              fingerName: fingerName,
            ));
          }
        }
      }
    }
    
    return overlays;
  }

  // 개별 손가락 점 위젯
  Widget _buildFingerDot({
    required double x,
    required double y,
    required String fingerName,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenX = x * screenSize.width;
    final screenY = y * screenSize.height;
    
    Color dotColor;
    double dotSize;
    
    switch (fingerName) {
      case 'thumb':
        dotColor = Colors.red;
        dotSize = 15;
        break;
      case 'index':
        dotColor = Colors.green;
        dotSize = 12;
        break;
      case 'middle':
        dotColor = Colors.blue;
        dotSize = 10;
        break;
      case 'ring':
        dotColor = Colors.orange;
        dotSize = 8;
        break;
      case 'pinky':
        dotColor = Colors.purple;
        dotSize = 6;
        break;
      default:
        dotColor = Colors.white;
        dotSize = 8;
    }

    return Positioned(
      left: screenX - dotSize / 2,
      top: screenY - dotSize / 2,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: dotColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(dotSize / 2),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: dotColor.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  // 연결 상태 표시기
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _connectionStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 종료 버튼
  Widget _buildExitButton() {
    return GestureDetector(
      onTap: () async {
        await windowManager.setIgnoreMouseEvents(false);
        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  @override
  void onWindowEvent(String eventName) {
    print('🪟 Window event: $eventName');
  }

  @override
  void onWindowClose() {
    // 창 닫기 이벤트
    _channel?.sink.close();
  }

  @override
  void onWindowFocus() {
    // 창이 포커스를 받았을 때
    print('🎯 Overlay window focused');
  }

  @override
  void onWindowBlur() {
    // 창이 포커스를 잃었을 때
    print('😴 Overlay window blurred');
  }
}