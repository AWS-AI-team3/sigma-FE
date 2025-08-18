import 'package:flutter/foundation.dart';
import '../services/auth_storage_service.dart';
import '../services/google_auth_service.dart';
import '../utils/logger.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  Map<String, dynamic>? _userInfo;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  void _setState(AuthState newState, {String? error}) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setState(AuthState.loading);
    
    try {
      final result = await GoogleAuthService.signInWithGoogle();
      
      if (result != null && result['success'] == true) {
        _userInfo = result['data'];
        _setState(AuthState.authenticated);
        AuthLogger.success('Google 로그인 성공');
      } else {
        _setState(AuthState.unauthenticated, 
                 error: result?['error'] ?? 'Google 로그인 실패');
      }
    } catch (e) {
      AuthLogger.error('Google 로그인 오류', e);
      _setState(AuthState.error, error: e.toString());
    }
  }

  Future<void> logout() async {
    _setState(AuthState.loading);
    
    try {
      await GoogleAuthService.logout();
      _userInfo = null;
      _setState(AuthState.unauthenticated);
      AuthLogger.success('로그아웃 완료');
    } catch (e) {
      AuthLogger.error('로그아웃 오류', e);
      _setState(AuthState.error, error: e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    if (AuthStorageService.hasAccessToken) {
      _setState(AuthState.authenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}