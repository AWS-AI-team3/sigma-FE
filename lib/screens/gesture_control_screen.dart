import 'package:flutter/material.dart';
import '../services/gesture_control_service.dart';

/// 제스처 제어 서비스 화면 - 간단하고 명확한 UI
class GestureControlScreen extends StatefulWidget {
  const GestureControlScreen({Key? key}) : super(key: key);

  @override
  State<GestureControlScreen> createState() => _GestureControlScreenState();
}

class _GestureControlScreenState extends State<GestureControlScreen> {
  bool isServiceRunning = false;
  bool hasOverlayPermission = false;
  bool hasAccessibilityPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// 권한 상태 확인
  Future<void> _checkPermissions() async {
    final overlay = await GestureControlService.checkOverlayPermission();
    final accessibility = await GestureControlService.checkAccessibilityEnabled();

    setState(() {
      hasOverlayPermission = overlay;
      hasAccessibilityPermission = accessibility;
    });
  }

  /// 서비스 시작/정지 토글
  Future<void> _toggleService() async {
    if (isServiceRunning) {
      // 서비스 정지
      await GestureControlService.stopService();
      setState(() {
        isServiceRunning = false;
      });
    } else {
      // 권한 확인 후 서비스 시작
      await _checkPermissions();

      if (!hasOverlayPermission) {
        _showPermissionDialog('오버레이 권한이 필요합니다');
        return;
      }

      if (!hasAccessibilityPermission) {
        _showPermissionDialog('접근성 권한이 필요합니다');
        return;
      }

      final success = await GestureControlService.startService();
      setState(() {
        isServiceRunning = success;
      });
    }
  }

  /// 권한 안내 다이얼로그
  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGMA 제스처 제어'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 서비스 상태 표시
            _buildStatusCard(),

            const SizedBox(height: 32),

            // 권한 상태 표시
            _buildPermissionCard(),

            const SizedBox(height: 32),

            // 서비스 시작/정지 버튼
            _buildControlButton(),
          ],
        ),
      ),
    );
  }

  /// 서비스 상태 카드
  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              isServiceRunning ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 64,
              color: isServiceRunning ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isServiceRunning ? '서비스 실행 중' : '서비스 정지됨',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// 권한 상태 카드
  Widget _buildPermissionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '권한 상태',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPermissionRow(
              '오버레이 권한',
              hasOverlayPermission,
              () async {
                await GestureControlService.openOverlaySettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkPermissions();
              },
            ),
            const SizedBox(height: 12),
            _buildPermissionRow(
              '접근성 권한',
              hasAccessibilityPermission,
              () async {
                await GestureControlService.openAccessibilitySettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkPermissions();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 권한 상태 행
  Widget _buildPermissionRow(String title, bool granted, VoidCallback onTap) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 16)),
        ),
        if (!granted)
          TextButton(
            onPressed: onTap,
            child: const Text('설정'),
          ),
      ],
    );
  }

  /// 서비스 제어 버튼
  Widget _buildControlButton() {
    return ElevatedButton(
      onPressed: _toggleService,
      style: ElevatedButton.styleFrom(
        backgroundColor: isServiceRunning ? Colors.red : Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        isServiceRunning ? '서비스 정지' : '서비스 시작',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
