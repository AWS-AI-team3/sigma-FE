import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/face_service.dart';
import '../services/face_auth_service.dart';
import '../services/camera_manager.dart';
import '../utils/logger.dart';

enum FaceState { initial, loading, success, error, cameraReady }

class FaceProvider with ChangeNotifier {
  FaceState _state = FaceState.initial;
  String? _errorMessage;
  CameraController? _cameraController;
  bool _isRegistered = false;

  FaceState get state => _state;
  String? get errorMessage => _errorMessage;
  CameraController? get cameraController => _cameraController;
  bool get isRegistered => _isRegistered;
  bool get isLoading => _state == FaceState.loading;

  void _setState(FaceState newState, {String? error}) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> initializeCamera() async {
    _setState(FaceState.loading);
    
    try {
      _cameraController = await CameraManager.instance.initializeCamera();
      if (_cameraController != null) {
        _setState(FaceState.cameraReady);
        Logger.info('카메라 초기화 완료', 'FACE');
      } else {
        _setState(FaceState.error, error: '카메라 초기화 실패');
      }
    } catch (e) {
      Logger.error('카메라 초기화 오류', 'FACE', e);
      _setState(FaceState.error, error: e.toString());
    }
  }

  Future<void> registerFace(Uint8List imageBytes) async {
    _setState(FaceState.loading);
    
    try {
      // 1. Presigned URL 요청
      final presignedResponse = await FaceService.getPresignedUrl();
      if (presignedResponse == null || presignedResponse['sucess'] != true) {
        throw Exception('Presigned URL 획득 실패');
      }

      final presignedUrl = presignedResponse['data']['presignedUrl'];
      final objectKey = presignedResponse['data']['objectKey'];

      // 2. S3 업로드
      final uploadSuccess = await FaceService.uploadImageToS3(
        presignedUrl, 
        imageBytes, 
        'image/jpeg'
      );
      
      if (!uploadSuccess) {
        throw Exception('이미지 업로드 실패');
      }

      // 3. 얼굴 등록 완료
      final completeResponse = await FaceService.completeFaceRegistration(objectKey);
      if (completeResponse == null || completeResponse['sucess'] != true) {
        throw Exception('얼굴 등록 완료 실패');
      }

      _isRegistered = true;
      _setState(FaceState.success);
      Logger.info('얼굴 등록 완료', 'FACE');
      
    } catch (e) {
      Logger.error('얼굴 등록 오류', 'FACE', e);
      _setState(FaceState.error, error: e.toString());
    }
  }

  Future<void> authenticateFace(Uint8List imageBytes) async {
    _setState(FaceState.loading);
    
    try {
      // 1. 얼굴 인증용 Presigned URL 요청
      final presignedResponse = await FaceAuthService.checkRegistrationAndGetPresignedUrl();
      if (presignedResponse == null) {
        throw Exception('얼굴 인증 요청 실패');
      }

      if (presignedResponse['error']?['code'] == 'FACE_NOT_REGISTERED') {
        _setState(FaceState.error, error: '등록된 얼굴이 없습니다');
        return;
      }

      final presignedUrl = presignedResponse['data']['presignedUrl'];
      final authPhotoKey = presignedResponse['data']['authPhotokey'];

      // 2. S3 업로드
      final uploadSuccess = await FaceAuthService.uploadAuthImageToS3(
        presignedUrl, 
        imageBytes, 
        'image/jpeg'
      );
      
      if (!uploadSuccess) {
        throw Exception('인증 이미지 업로드 실패');
      }

      // 3. 얼굴 인증 완료
      final authResponse = await FaceAuthService.completeFaceAuth(authPhotoKey);
      if (authResponse == null || authResponse['sucess'] != true) {
        throw Exception('얼굴 인증 실패');
      }

      _setState(FaceState.success);
      Logger.info('얼굴 인증 완료', 'FACE');
      
    } catch (e) {
      Logger.error('얼굴 인증 오류', 'FACE', e);
      _setState(FaceState.error, error: e.toString());
    }
  }

  Future<void> checkFaceSession() async {
    try {
      final result = await FaceAuthService.checkFaceSession();
      if (result != null && result['sucess'] == true) {
        _setState(FaceState.success);
      } else {
        _setState(FaceState.error, error: '얼굴 인증이 필요합니다');
      }
    } catch (e) {
      Logger.error('얼굴 세션 확인 오류', 'FACE', e);
      _setState(FaceState.error, error: e.toString());
    }
  }

  void disposeCamera() {
    CameraManager.instance.dispose();
    _cameraController = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}