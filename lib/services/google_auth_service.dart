import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'auth_storage_service.dart';

class GoogleAuthService {
  static const String clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', 
    defaultValue: 'your_google_client_id_here');
  static const String clientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET', 
    defaultValue: 'your_google_client_secret_here');
  static const String redirectUri = 'http://localhost:8080/login/oauth2/code/google';
  static HttpServer? _callbackServer;
  static Completer<String?>? _authCompleter;

  static Future<String?> signInAndGetIdToken() async {
    try {
      // 1. 브라우저에서 authorization code 받기
      final String? code = await _getAuthorizationCode();
      if (code == null) {
        print('Failed to get authorization code');
        return null;
      }

      // 2. authorization code를 idToken으로 교환
      final String? idToken = await _exchangeCodeForIdToken(code);
      if (idToken == null) {
        print('Failed to exchange code for idToken');
        return null;
      }

      print('Successfully got ID token');
      print('ID Token: $idToken');
      return idToken;
    } catch (error) {
      print('Google Sign In Error: $error');
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
          '&redirect_uri=$redirectUri'
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
      print('Authorization Error: $error');
      await _stopCallbackServer();
      return null;
    }
  }

  static Future<void> _startCallbackServer() async {
    _authCompleter = Completer<String?>();
    
    try {
      _callbackServer = await HttpServer.bind('localhost', 8080);
      print('Callback server started on http://localhost:8080');
      
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
            print('OAuth error: $error');
            _authCompleter!.complete(null);
          } else if (code != null) {
            print('Authorization code received: $code');
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
      print('Error starting callback server: $e');
      _authCompleter!.complete(null);
    }
  }

  static Future<void> _stopCallbackServer() async {
    if (_callbackServer != null) {
      await _callbackServer!.close();
      _callbackServer = null;
      print('Callback server stopped');
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
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id_token']; // idToken 반환
      } else {
        print('Token exchange error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      print('Token exchange error: $error');
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
      print('Signed out successfully');
    } catch (error) {
      print('Google Sign Out Error: $error');
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
        print('Server auth error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      print('Network error: $error');
      return null;
    }
  }

  static Future<bool> logout() async {
    try {
      final headers = <String, String>{};
      
      // Access Token이 있으면 Authorization 헤더 추가
      if (AuthStorageService.hasAccessToken) {
        headers['Authorization'] = 'Bearer ${AuthStorageService.accessToken}';
      }
      
      final response = await http.post(
        Uri.parse('https://www.3-sigma-server.com/v1/auth/logout'),
        headers: headers,
        body: '', // 빈 body로 요청
      );

      print('Logout response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        // 로그아웃 성공 시 로컬 토큰 삭제
        AuthStorageService.clearTokens();
        return true;
      } else {
        print('Logout error: ${response.statusCode} ${response.body}');
        // 서버 로그아웃 실패해도 로컬 토큰은 삭제
        AuthStorageService.clearTokens();
        return false;
      }
    } catch (error) {
      print('Logout network error: $error');
      // 네트워크 오류라도 로컬 토큰은 삭제
      AuthStorageService.clearTokens();
      return false;
    }
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

      print('Sending ID Token to server...');
      final Map<String, dynamic>? serverResponse = await _sendIdTokenToServer(idToken);
      
      if (serverResponse != null) {
        print('Server Response: $serverResponse');
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