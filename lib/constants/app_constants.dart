class AppConstants {
  // Server URLs
  static const String baseUrl = 'https://www.3-sigma-server.com';
  static const String apiVersion = '/v1';
  
  // API Endpoints
  static const String authLogin = '$apiVersion/auth/google/login';
  static const String authLogout = '$apiVersion/auth/logout';
  static const String authReissue = '$apiVersion/auth/reissue';
  
  static const String userInfo = '$apiVersion/user/info';
  
  static const String faceRegisterPresign = '$apiVersion/faces/register/presign';
  static const String faceRegisterComplete = '$apiVersion/faces/register/complete';
  
  static const String faceAuthPresign = '$apiVersion/faces/auth/presign';
  static const String faceAuthComplete = '$apiVersion/faces/auth/complete';
  static const String faceSessionCheck = '$apiVersion/faces/session/check';
  
  static const String settingsMotion = '$apiVersion/settings/motion';
  static const String settingsSkeleton = '$apiVersion/settings/skeleton';
  static const String settingsCursor = '$apiVersion/settings/cursor';
  
  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded = 'application/x-www-form-urlencoded';
  static const String contentTypeImageJpeg = 'image/jpeg';
  
  // HTTP Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerAccept = 'accept';
  
  // OAuth - loaded from environment variables
  static const String oauthRedirectUri = 'http://localhost:8080/login/oauth2/code/google';
  static const String oauthScope = 'openid email profile';
  
  // Local Server
  static const String callbackHost = 'localhost';
  static const int callbackPort = 8080;
  
  // Token
  static const Duration tokenRefreshBuffer = Duration(minutes: 2); // 토큰 만료 2분 전에 갱신
  
  // App Info
  static const String appTitle = 'SIGMA - Smart Interactive Gesture Management Assistant';
  static const String appVersion = '1.0.0';
  
  // Window Settings
  static const double windowWidth = 480;
  static const double windowHeight = 650;
  
  // Colors (Hex values)
  static const int primaryColorValue = 0xFF6366F1;
  static const int scaffoldBackgroundColorValue = 0xFFE5E5E5;
  
  // Gesture Mappings
  // UI 드롭다운 옵션들
  static const String gestureThumbIndex = '엄지와 검지를';     // M1 - 엄지+검지 핀치
  static const String gestureThumbMiddle = '엄지와 중지를';    // M2 - 엄지+중지 핀치  
  static const String gestureThumbPinky = '엄지와 새끼를';    // M3 - 엄지+새끼 핀치
  static const String gestureUnassigned = '선택 안함';
  
  // 서버 모션 코드
  static const String motionM1 = 'M1';  // 엄지+검지 핀치
  static const String motionM2 = 'M2';  // 엄지+중지 핀치
  static const String motionM3 = 'M3';  // 엄지+새끼 핀치
  static const String motionUnassigned = 'UNASSIGNED';
}