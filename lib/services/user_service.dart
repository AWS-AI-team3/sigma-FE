import 'api_client.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserInfo() async {
    return await ApiClient.get('/v1/user/info');
  }
}