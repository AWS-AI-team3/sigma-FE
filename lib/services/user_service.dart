import 'api_client.dart';

class UserService {
  // Get user information (profile, subscription status)
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      print('📤 Getting user info from /v1/user/info');
      final result = await ApiClient.get('/v1/user/info');

      if (result != null) {
        print('📨 User info received: $result');
        return result;
      }

      print('❌ Failed to get user info');
      return null;
    } catch (error) {
      print('❌ User info error: $error');
      return null;
    }
  }
}
