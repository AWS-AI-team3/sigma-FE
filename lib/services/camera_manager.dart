import 'package:camera/camera.dart';

class CameraManager {
  static CameraManager? _instance;
  static CameraManager get instance => _instance ??= CameraManager._();
  
  CameraManager._();
  
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  CameraController? get controller => _controller;
  
  Future<CameraController?> initializeCamera() async {
    // 이미 초기화되었거나 진행 중이면 기존 컨트롤러 반환
    if (_isInitialized && _controller != null) {
      print('카메라 이미 초기화됨 - 기존 컨트롤러 반환');
      return _controller;
    }
    
    if (_isInitializing) {
      print('카메라 초기화 진행 중 - 대기');
      // 초기화가 완료될 때까지 대기
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _controller;
    }
    
    _isInitializing = true;
    print('카메라 초기화 시작...');
    
    try {
      // 기존 컨트롤러 안전하게 해제
      await _disposeController();
      
      // 카메라 리소스 완전 해제 대기
      await Future.delayed(const Duration(milliseconds: 300));
      
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // 전면 카메라 찾기
        CameraDescription? frontCamera;
        for (final camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }
        
        final selectedCamera = frontCamera ?? cameras.first;
        
        _controller = CameraController(
          selectedCamera,
          ResolutionPreset.medium,
        );
        
        await _controller!.initialize();
        _isInitialized = true;
        
        print('카메라 초기화 완료 - 비율: ${_controller!.value.aspectRatio}');
        print('카메라 해상도: ${_controller!.value.previewSize}');
        
        return _controller;
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
      await _disposeController();
    } finally {
      _isInitializing = false;
    }
    
    return null;
  }
  
  Future<void> _disposeController() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isInitialized) {
          await _controller!.dispose();
          print('카메라 컨트롤러 해제됨');
        }
      } catch (e) {
        print('카메라 해제 오류: $e');
      }
      _controller = null;
      _isInitialized = false;
    }
  }
  
  Future<void> dispose() async {
    await _disposeController();
    _isInitializing = false;
  }
  
  Future<void> reset() async {
    print('카메라 매니저 리셋');
    await dispose();
  }
}