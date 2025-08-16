import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'auth_storage_service.dart';

class FaceAuthService {
  static const String baseUrl = 'https://www.3-sigma-server.com';

  // 얼굴 등록 여부 확인 및 인증용 presigned URL 요청
  static Future<Map<String, dynamic>?> checkRegistrationAndGetPresignedUrl() async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Access Token이 있으면 Authorization 헤더 추가
      if (AuthStorageService.hasAccessToken) {
        headers['Authorization'] = 'Bearer ${AuthStorageService.accessToken}';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/v1/faces/auth/presign'),
        headers: headers,
        body: json.encode({
          'contentType': 'image/jpeg',
        }),
      );

      print('Face auth presign response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Face auth presign error: ${response.statusCode} ${response.body}');
        // 에러 응답도 파싱해서 반환 (FACE_NOT_REGISTERED 체크용)
        try {
          final errorData = json.decode(response.body);
          return errorData;
        } catch (e) {
          return null;
        }
      }
    } catch (error) {
      print('Face auth presign network error: $error');
      return null;
    }
  }

  // S3에 인증용 이미지 업로드
  static Future<bool> uploadAuthImageToS3(String presignedUrl, Uint8List imageBytes, String contentType) async {
    try {
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: imageBytes,
      );

      print('S3 auth image upload response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (error) {
      print('S3 auth image upload error: $error');
      return false;
    }
  }

  // 얼굴 인증 완료 요청
  static Future<Map<String, dynamic>?> completeFaceAuth(String authPhotoKey) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Access Token이 있으면 Authorization 헤더 추가
      if (AuthStorageService.hasAccessToken) {
        headers['Authorization'] = 'Bearer ${AuthStorageService.accessToken}';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/v1/faces/auth/complete'),
        headers: headers,
        body: json.encode({
          'authPhotokey': authPhotoKey, // API 스펙에 맞춘 키 이름
        }),
      );

      print('Face auth complete response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Face auth complete error: ${response.statusCode} ${response.body}');
        // 에러 응답도 파싱해서 반환
        try {
          final errorData = json.decode(response.body);
          return errorData;
        } catch (e) {
          return null;
        }
      }
    } catch (error) {
      print('Face auth complete network error: $error');
      return null;
    }
  }

  // 얼굴 인증 세션 체크
  static Future<Map<String, dynamic>?> checkFaceSession() async {
    try {
      final headers = <String, String>{};
      
      // Access Token이 있으면 Authorization 헤더 추가
      if (AuthStorageService.hasAccessToken) {
        headers['Authorization'] = 'Bearer ${AuthStorageService.accessToken}';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/v1/faces/session/check'),
        headers: headers,
        body: '', // 빈 body로 요청
      );

      print('Face session check response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // 401 에러도 파싱해서 반환 (FACE_UNAUTHORIZED 체크용)
        try {
          final errorData = json.decode(response.body);
          return errorData;
        } catch (e) {
          return {
            'data': null,
            'error': {
              'code': 'FACE_UNAUTHORIZED',
              'message': '얼굴인증이 아직 진행되지 않았습니다.'
            },
            'success': false
          };
        }
      } else {
        print('Face session check error: ${response.statusCode} ${response.body}');
        try {
          final errorData = json.decode(response.body);
          return errorData;
        } catch (e) {
          return null;
        }
      }
    } catch (error) {
      print('Face session check network error: $error');
      return null;
    }
  }
}