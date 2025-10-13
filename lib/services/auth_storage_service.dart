import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthStorageService {
  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  // Access Token
  static Future<void> saveAccessToken(String token, DateTime expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
    await prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());
    print('✅ Access token saved, expires at: $expiresAt');
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_tokenExpiryKey);
    if (expiryStr == null) return null;
    return DateTime.parse(expiryStr);
  }

  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
    print('✅ Refresh token saved');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Token validation
  static Future<bool> isTokenValid() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;

    final now = DateTime.now();
    final bufferTime = now.add(AppConstants.tokenRefreshBuffer);

    return expiry.isAfter(bufferTime);
  }

  // Get valid access token (refresh if needed)
  static Future<String?> getValidAccessToken() async {
    if (await isTokenValid()) {
      return await getAccessToken();
    }

    // Token expired or will expire soon - need to refresh
    // This will be handled by GoogleAuthService
    return null;
  }

  // Clear all tokens
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    print('🗑️ All tokens cleared');
  }
}
