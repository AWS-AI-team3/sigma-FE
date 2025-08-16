class AuthStorageService {
  static String? _accessToken;
  static String? _refreshToken;

  static void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    print('Tokens saved - Access: ${accessToken.substring(0, 20)}...');
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    print('Tokens cleared');
  }

  static bool get hasAccessToken => _accessToken != null;
}