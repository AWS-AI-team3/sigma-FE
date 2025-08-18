import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_storage_service.dart';

class UserService {
  static const String baseUrl = 'https://www.3-sigma-server.com';

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final headers = <String, String>{};
      
      // 유효한 Access Token 가져오기 (자동 갱신 포함)
      final validToken = await AuthStorageService.getValidAccessToken();
      if (validToken != null) {
        headers['Authorization'] = 'Bearer $validToken';
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