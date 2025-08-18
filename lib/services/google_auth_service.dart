import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'auth_storage_service.dart';
import 'env_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class GoogleAuthService {
  static String get clientId => EnvService.googleClientId;
  static String get clientSecret => EnvService.googleClientSecret;
  static HttpServer? _callbackServer;
  static Completer<String?>? _authCompleter;

  static Future<String?> signInAndGetIdToken() async {
    try {
      // 1. 브라우저에서 authorization code 받기
      final String? code = await _getAuthorizationCode();
      if (code == null) {
        return null;
      }

      // 2. authorization code를 idToken으로 교환
      final String? idToken = await _exchangeCodeForIdToken(code);
      if (idToken == null) {
        return null;
      }

      return idToken;
    } catch (error) {
      return null;
    }
  }

  static Future<String?> _getAuthorizationCode() async {
    try {
      // 로컬 서버 시작
      await _startCallbackServer();
      
      const scope = 'openid email profile';
      final state = _generateRandomString(32);
      
      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
          '?client_id=$clientId'
          '&redirect_uri=${AppConstants.oauthRedirectUri}'
          '&response_type=code'
          '&scope=$scope'
          '&state=$state';

      // 브라우저에서 인증 URL 열기
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch browser');
      }

      // authorization code 대기
      return await _authCompleter!.future;
    } catch (error) {
      await _stopCallbackServer();
      return null;
    }
  }

  static Future<void> _startCallbackServer() async {
    _authCompleter = Completer<String?>();
    
    try {
      _callbackServer = await HttpServer.bind('localhost', 8080);
      
      _callbackServer!.listen((HttpRequest request) async {
        // /login/oauth2/code/google 경로만 처리
        if (request.uri.path == '/login/oauth2/code/google') {
          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];

          // 브라우저에 응답 페이지 표시
          request.response
            ..statusCode = 200
            ..headers.set('Content-Type', 'text/html; charset=utf-8')
            ..write('''
              <html>
                <head>
                  <meta charset="UTF-8">
                  <title>SIGMA Login</title>
                </head>
                <body>
                  <h2>Login ${error != null ? 'Failed' : 'Successful'}</h2>
                  <p>${error != null ? 'Login failed. Please try again.' : 'Login completed successfully. You can close this window.'}</p>
                  <script>setTimeout(() => window.close(), 2000);</script>
                </body>
              </html>
            ''');
          await request.response.close();

          if (error != null) {
            _authCompleter!.complete(null);
          } else if (code != null) {
            print('✅ 인증 코드 수신');
            _authCompleter!.complete(code);
          }
          
          await _stopCallbackServer();
        } else {
          // 다른 경로는 404 처리
          request.response
            ..statusCode = 404
            ..write('Not Found');
          await request.response.close();
        }
      });
    } catch (e) {
      _authCompleter!.complete(null);
    }
  }

  static Future<void> _stopCallbackServer() async {
    if (_callbackServer != null) {
      await _callbackServer!.close();
      _callbackServer = null;
    }
  }

  static Future<String?> _exchangeCodeForIdToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': AppConstants.oauthRedirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id_token']; // idToken 반환
      } else {
        Logger.error('토큰 교환 실패: ${response.statusCode}', 'AUTH');
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<void> signOut() async {
    try {
    } catch (error) {
    }
  }


  static Future<Map<String, dynamic>?> _sendIdTokenToServer(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.3-sigma-server.com/v1/auth/google/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'idToken': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ 서버 인증 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  static Future<bool> logout() async {
    final result = await http.post(
      Uri.parse('https://www.3-sigma-server.com/v1/auth/logout'),
      headers: {
        'Authorization': 'Bearer ${await AuthStorageService.getValidAccessToken() ?? ''}',
      },
      body: '',
    );
    
    // 결과에 관계없이 로컬 토큰 삭제
    AuthStorageService.clearTokens();
    return result.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final String? idToken = await signInAndGetIdToken();
      
      if (idToken == null) {
        return {
          'success': false,
          'error': 'Google sign in failed',
        };
      }

      final Map<String, dynamic>? serverResponse = await _sendIdTokenToServer(idToken);
      
      if (serverResponse != null) {
      }
      
      if (serverResponse != null && serverResponse['sucess'] == true) {
        // 토큰 저장
        final data = serverResponse['data'];
        if (data != null && data['accessToken'] != null && data['refreshToken'] != null) {
          AuthStorageService.setTokens(data['accessToken'], data['refreshToken']);
        }
        
        return {
          'success': true,
          'data': serverResponse['data'],
        };
      } else {
        return {
          'success': false,
          'error': serverResponse?['error'] ?? 'Server authentication failed',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': error.toString(),
      };
    }
  }
}