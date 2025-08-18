import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class AuthStorageService {
  static String? _accessToken;
  static String? _refreshToken;

  static void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static bool get hasAccessToken => _accessToken != null;
  static bool get hasRefreshToken => _refreshToken != null;

  // 토큰 만료 여부 확인
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationTime);
    } catch (e) {
      return true;
    }
  }

  // 토큰 재발급
  static Future<bool> reissueToken() async {
    if (!hasRefreshToken) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authReissue}'),
        headers: {
          AppConstants.headerAccept: '*/*',
          AppConstants.headerAuthorization: 'Bearer $_accessToken',
          AppConstants.headerContentType: AppConstants.contentTypeJson,
        },
        body: json.encode({
          'refreshToken': _refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucess'] == true && data['data'] != null) {
          final tokenData = data['data'];
          setTokens(tokenData['accessToken'], tokenData['refreshToken']);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // 토큰 유효성 검사 및 자동 갱신
  static Future<String?> getValidAccessToken() async {
    if (!hasAccessToken) return null;
    
    if (isTokenExpired(_accessToken!)) {
      AuthLogger.token('토큰 갱신 중...');
      final success = await reissueToken();
      if (!success) {
        clearTokens();
        return null;
      }
    }
    
    return _accessToken;
  }
}