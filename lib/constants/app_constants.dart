class AppConstants {
  // Server URLs
  static const String baseUrl = 'https://www.3-sigma-server.com';
  static const String apiVersion = '/v1';

  // API Endpoints
  static const String authLogin = '$apiVersion/auth/google/login';
  static const String authLogout = '$apiVersion/auth/logout';
  static const String authReissue = '$apiVersion/auth/reissue';

  static const String userInfo = '$apiVersion/user/info';

  static const String faceRegisterPresign =
      '$apiVersion/faces/register/presign';
  static const String faceRegisterComplete =
      '$apiVersion/faces/register/complete';

  static const String faceAuthPresign = '$apiVersion/faces/auth/presign';
  static const String faceAuthComplete = '$apiVersion/faces/auth/complete';
  static const String faceSessionCheck = '$apiVersion/faces/session/check';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeImageJpeg = 'image/jpeg';

  // HTTP Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';

  // Token
  static const Duration tokenRefreshBuffer = Duration(minutes: 2);
}
