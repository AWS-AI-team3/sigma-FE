import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'auth_storage_service.dart';

class FaceService {
  static const String baseUrl = 'https://www.3-sigma-server.com';

  static Future<Map<String, dynamic>?> getPresignedUrl() async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // 유효한 Access Token 가져오기 (자동 갱신 포함)
      final validToken = await AuthStorageService.getValidAccessToken();
      if (validToken != null) {
        headers['Authorization'] = 'Bearer $validToken';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/v1/faces/register/presign'),
        headers: headers,
        body: json.encode({
          'contentType': 'image/jpeg',
        }),
      );

      print('Presigned URL response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Presigned URL error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      print('Presigned URL network error: $error');
      return null;
    }
  }

  static Future<bool> uploadImageToS3(String presignedUrl, Uint8List imageBytes, String contentType) async {
    try {
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: imageBytes,
      );

      print('S3 upload response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (error) {
      print('S3 upload error: $error');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> completeFaceRegistration(String objectKey) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // 유효한 Access Token 가져오기 (자동 갱신 포함)
      final validToken = await AuthStorageService.getValidAccessToken();
      if (validToken != null) {
        headers['Authorization'] = 'Bearer $validToken';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/v1/faces/register/complete'),
        headers: headers,
        body: json.encode({
          'objectKey': objectKey,
        }),
      );

      print('Face registration complete response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Face registration complete error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      print('Face registration complete network error: $error');
      return null;
    }
  }
}