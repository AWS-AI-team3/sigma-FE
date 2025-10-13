import 'dart:typed_data';
import 'api_client.dart';

class FaceAuthService {
  static Future<Map<String, dynamic>?> checkRegistrationAndGetPresignedUrl() async {
    return await ApiClient.post('/v1/faces/auth/presign', body: {
      'contentType': 'image/jpeg',
    });
  }

  static Future<bool> uploadAuthImageToS3(String presignedUrl, Uint8List imageBytes, String contentType) async {
    return await ApiClient.uploadToS3(presignedUrl, imageBytes, contentType: contentType);
  }

  static Future<Map<String, dynamic>?> completeFaceAuth(String authPhotoKey) async {
    return await ApiClient.post('/v1/faces/auth/complete', body: {
      'authPhotokey': authPhotoKey,
    });
  }

  static Future<Map<String, dynamic>?> checkFaceSession() async {
    final result = await ApiClient.post('/v1/faces/session/check');
    
    // 401 에러 시 기본 응답 반환
    if (result == null) {
      return {
        'data': null,
        'error': {
          'code': 'FACE_UNAUTHORIZED',
          'message': '얼굴인증이 아직 진행되지 않았습니다.'
        },
        'success': false
      };
    }
    
    return result;
  }
}