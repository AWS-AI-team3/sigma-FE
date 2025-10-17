import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'api_client.dart';

class FaceAuthService {
  // Camera initialization
  Future<CameraController?> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // Use front camera for face auth
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      return controller;
    } catch (e) {
      print('❌ Camera initialization error: $e');
      return null;
    }
  }

  // Get presigned URL for face auth
  Future<Map<String, dynamic>?> getPresignedUrl() async {
    return await ApiClient.post(
      '/v1/faces/auth/presign',
      body: {'contentType': 'image/jpeg'},
    );
  }

  // Upload image to S3
  Future<bool> uploadImageToS3(
    String presignedUrl,
    Uint8List imageBytes,
  ) async {
    return await ApiClient.uploadToS3(
      presignedUrl,
      imageBytes,
      contentType: 'image/jpeg',
    );
  }

  // Legacy static methods (deprecated)
  static Future<Map<String, dynamic>?>
  checkRegistrationAndGetPresignedUrl() async {
    return await ApiClient.post(
      '/v1/faces/auth/presign',
      body: {'contentType': 'image/jpeg'},
    );
  }

  static Future<bool> uploadAuthImageToS3(
    String presignedUrl,
    Uint8List imageBytes,
    String contentType,
  ) async {
    return await ApiClient.uploadToS3(
      presignedUrl,
      imageBytes,
      contentType: contentType,
    );
  }

  // Complete face authentication
  Future<Map<String, dynamic>?> completeFaceAuth(
    String authPhotoKey,
  ) async {
    return await ApiClient.post(
      '/v1/faces/auth/complete',
      body: {'authPhotokey': authPhotoKey},
    );
  }

  // Legacy static method (deprecated)
  static Future<Map<String, dynamic>?> completeFaceAuthStatic(
    String authPhotoKey,
  ) async {
    return await ApiClient.post(
      '/v1/faces/auth/complete',
      body: {'authPhotokey': authPhotoKey},
    );
  }

  static Future<Map<String, dynamic>?> checkFaceSession() async {
    final result = await ApiClient.post('/v1/faces/session/check');

    // 401 에러 시 기본 응답 반환
    if (result == null) {
      return {
        'data': null,
        'error': {
          'code': 'FACE_UNAUTHORIZED',
          'message': '얼굴인증이 아직 진행되지 않았습니다.',
        },
        'success': false,
      };
    }

    return result;
  }

  // 전체 얼굴 인증 프로세스 (이미지 경로로)
  static Future<Map<String, dynamic>?> authenticate(String imagePath) async {
    try {
      // 1. Presigned URL 가져오기
      final presignedResult = await checkRegistrationAndGetPresignedUrl();
      if (presignedResult == null || presignedResult['data'] == null) {
        return {'success': false, 'error': 'Failed to get presigned URL'};
      }

      final presignedUrl = presignedResult['data']['presignedUrl'];
      final authPhotoKey = presignedResult['data']['authPhotokey'];

      // 2. 이미지 읽기
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // 3. S3에 업로드
      final uploadSuccess = await uploadAuthImageToS3(
        presignedUrl,
        imageBytes,
        'image/jpeg',
      );

      if (!uploadSuccess) {
        return {'success': false, 'error': 'Failed to upload image'};
      }

      // 4. 인증 완료 API 호출
      final completeResult = await completeFaceAuthStatic(authPhotoKey);
      return completeResult;
    } catch (e) {
      print('❌ Authentication error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
