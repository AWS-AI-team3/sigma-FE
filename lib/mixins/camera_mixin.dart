import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_manager.dart';
import '../utils/logger.dart';

/// 카메라 초기화와 해제를 공통으로 처리하는 Mixin
mixin CameraMixin<T extends StatefulWidget> on State<T> {
  CameraController? _controller;
  bool _isCameraReady = false;

  /// 카메라 컨트롤러 getter
  CameraController? get cameraController => _controller;

  /// 카메라 준비 상태 getter
  bool get isCameraReady => _isCameraReady;

  /// 카메라 초기화
  Future<void> initializeCamera() async {
    try {
      _controller = await CameraManager.instance.initializeCamera();
      if (mounted && _controller != null) {
        setState(() {
          _isCameraReady = true;
        });
        onCameraInitialized();
      }
    } catch (e) {
      Logger.error('카메라 초기화 실패', 'CAMERA_MIXIN', e);
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
        onCameraInitializeFailed(e);
      }
    }
  }

  /// 카메라 해제
  void disposeCamera() {
    try {
      CameraManager.instance.dispose();
      _controller?.dispose();
      _controller = null;
      _isCameraReady = false;
    } catch (e) {
      Logger.error('카메라 해제 실패', 'CAMERA_MIXIN', e);
    }
  }

  /// 카메라 재시작
  Future<void> restartCamera() async {
    disposeCamera();
    await Future.delayed(const Duration(milliseconds: 100));
    await initializeCamera();
  }

  /// 카메라가 성공적으로 초기화되었을 때 호출되는 콜백
  void onCameraInitialized() {}

  /// 카메라 초기화가 실패했을 때 호출되는 콜백
  void onCameraInitializeFailed(dynamic error) {}

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}

/// 카메라가 필요한 화면에서 자동으로 초기화/해제를 처리하는 Mixin
mixin AutoCameraMixin<T extends StatefulWidget> on State<T>, CameraMixin<T> {
  @override
  void initState() {
    super.initState();
    // 다음 프레임에서 카메라 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeCamera();
    });
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}

/// 카메라 상태를 표시하는 공통 위젯
class CameraStatusIndicator extends StatelessWidget {
  final bool isCameraReady;
  final String? errorMessage;

  const CameraStatusIndicator({
    super.key,
    required this.isCameraReady,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isCameraReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.videocam, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text(
              '카메라 준비됨',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Text(
              errorMessage ?? '카메라 초기화 중...',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }
}