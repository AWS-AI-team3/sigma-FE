import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_storage_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '733126943224-8cj8bbhuiftpcfque2t3mq83dcqj16nq.apps.googleusercontent.com',
    scopes: ['email', 'profile', 'openid'],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  // 로그인 상태 확인 (토큰 기반)
  Future<bool> isLoggedIn() async {
    final token = await AuthStorageService.getValidAccessToken();
    return token != null;
  }

  // 구글 로그인 - new_layout 스타일로 Map 반환
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🔵 GoogleAuthService: Starting signIn...');
      final account = await _googleSignIn.signIn();
      print('🔵 GoogleAuthService: signIn completed, account=$account');

      if (account == null) {
        print('⚠️ Google Sign In returned null (user cancelled?)');
        return {'success': false, 'error': 'User cancelled sign in'};
      }

      _currentUser = account;

      // ID Token 가져오기
      final auth = await account.authentication;
      final idToken = auth.idToken;

      print('🔑 ID Token (full): $idToken');
      print('🔑 Access Token (full): ${auth.accessToken}');
      print('🔑 Server Auth Code (full): ${auth.serverAuthCode}');

      if (idToken == null) {
        print('❌ ID Token is null');
        return {'success': false, 'error': 'Failed to get ID token'};
      }

      print('📡 Sending ID Token to backend...');

      // 백엔드 API로 ID Token 전송 (필수)
      final response = await ApiClient.post(
        '/v2/auth/google/login',
        body: {'idToken': idToken},
        includeAuth: false,
      );

      if (response != null &&
          (response['sucess'] == true || response['success'] == true)) {
        // 토큰 저장
        final data = response['data'];
        if (data != null &&
            data['accessToken'] != null &&
            data['refreshToken'] != null) {
          final accessToken = data['accessToken'] as String;
          final refreshToken = data['refreshToken'] as String;
          final expiresIn = data['expiresIn'] as int? ?? 3600; // default 1 hour

          final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

          await AuthStorageService.saveAccessToken(accessToken, expiresAt);
          await AuthStorageService.saveRefreshToken(refreshToken);

          print('✅ Access token saved, expires at: $expiresAt');
        }

        // 사용자 정보 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', account.email);
        await prefs.setString('user_name', account.displayName ?? '');

        print('✅ Google Sign In Success: ${account.email}');

        return {'success': true, 'data': response['data']};
      } else {
        return {
          'success': false,
          'error': response?['error'] ?? 'Server authentication failed',
        };
      }
    } catch (error) {
      print('❌ Google Sign In Error: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 로그아웃
  Future<bool> signOut() async {
    try {
      print('🔵 Starting logout...');

      // 1. Call backend logout API
      final response = await ApiClient.post(
        '/v1/auth/logout',
        includeAuth: true,
      );

      if (response != null) {
        print('📡 Logout API response: $response');
      }

      // 2. Clear local tokens (regardless of API response)
      await AuthStorageService.clearTokens();

      // 3. Sign out from Google
      await _googleSignIn.signOut();
      _currentUser = null;

      // 4. Clear all local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ Sign Out Success');
      return true;
    } catch (error) {
      print('❌ Sign Out Error: $error');
      // Even if logout fails, clear local data
      await AuthStorageService.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return false;
    }
  }

  // 저장된 사용자 정보 가져오기
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email') ?? '',
      'name': prefs.getString('user_name') ?? '',
    };
  }
}
