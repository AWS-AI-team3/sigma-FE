import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // 전면 카메라 찾기
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        onCameraInitialized();
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
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
      _controller?.dispose();
      _controller = null;
      _isCameraReady = false;
    } catch (e) {
      print('카메라 해제 실패: $e');
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
