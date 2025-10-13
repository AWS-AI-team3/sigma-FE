import 'dart:typed_data';
import 'api_client.dart';

class FaceService {
  static Future<Map<String, dynamic>?> getPresignedUrl() async {
    return await ApiClient.post('/v1/faces/register/presign', body: {
      'contentType': 'image/jpeg',
    });
  }

  static Future<bool> uploadImageToS3(String presignedUrl, Uint8List imageBytes, String contentType) async {
    return await ApiClient.uploadToS3(presignedUrl, imageBytes, contentType: contentType);
  }

  static Future<Map<String, dynamic>?> completeFaceRegistration(String objectKey) async {
    return await ApiClient.post('/v1/faces/register/complete', body: {
      'objectKey': objectKey,
    });
  }
}