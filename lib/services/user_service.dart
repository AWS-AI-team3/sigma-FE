import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_storage_service.dart';

class UserService {
  static const String baseUrl = 'https://www.3-sigma-server.com';

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final headers = <String, String>{};
      
      // Access Token이 있으면 Authorization 헤더 추가
      if (AuthStorageService.hasAccessToken) {
        headers['Authorization'] = 'Bearer ${AuthStorageService.accessToken}';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/v1/user/info'),
        headers: headers,
      );

      print('User info response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('User info error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      print('User info network error: $error');
      return null;
    }
  }
}