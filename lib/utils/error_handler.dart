import 'package:flutter/material.dart';
import 'logger.dart';

enum ErrorType { network, auth, validation, camera, unknown }

class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final Object? originalError;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
  });

  factory AppError.network(String message, [Object? error]) {
    return AppError(
      message: message,
      type: ErrorType.network,
      originalError: error,
    );
  }

  factory AppError.auth(String message, [String? code, Object? error]) {
    return AppError(
      message: message,
      type: ErrorType.auth,
      code: code,
      originalError: error,
    );
  }

  factory AppError.validation(String message) {
    return AppError(
      message: message,
      type: ErrorType.validation,
    );
  }

  factory AppError.camera(String message, [Object? error]) {
    return AppError(
      message: message,
      type: ErrorType.camera,
      originalError: error,
    );
  }

  factory AppError.unknown(String message, [Object? error]) {
    return AppError(
      message: message,
      type: ErrorType.unknown,
      originalError: error,
    );
  }
}

class ErrorHandler {
  static void logError(AppError error) {
    final tag = _getErrorTag(error.type);
    Logger.error('${error.message}${error.code != null ? ' (${error.code})' : ''}', 
                 tag, error.originalError);
  }

  static String _getErrorTag(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'NETWORK';
      case ErrorType.auth:
        return 'AUTH';
      case ErrorType.validation:
        return 'VALIDATION';
      case ErrorType.camera:
        return 'CAMERA';
      case ErrorType.unknown:
        return 'ERROR';
    }
  }

  static void showErrorSnackBar(BuildContext context, AppError error) {
    logError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error.message)),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '닫기',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static Future<void> showErrorDialog(BuildContext context, AppError error) async {
    logError(error);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getErrorIcon(error.type), color: _getErrorColor(error.type)),
              const SizedBox(width: 8),
              Text(_getErrorTitle(error.type)),
            ],
          ),
          content: Text(error.message),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.camera:
        return Icons.camera_alt_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.auth:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.camera:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  static String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return '네트워크 오류';
      case ErrorType.auth:
        return '인증 오류';
      case ErrorType.validation:
        return '입력 오류';
      case ErrorType.camera:
        return '카메라 오류';
      case ErrorType.unknown:
        return '오류';
    }
  }

  // 에러를 AppError로 변환하는 유틸리티 메서드
  static AppError parseError(Object error) {
    if (error is AppError) return error;
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return AppError.network('네트워크 연결을 확인해주세요.', error);
    }
    
    if (errorString.contains('token') || 
        errorString.contains('auth') ||
        errorString.contains('unauthorized')) {
      return AppError.auth('인증에 실패했습니다. 다시 로그인해주세요.', null, error);
    }
    
    if (errorString.contains('camera')) {
      return AppError.camera('카메라 접근에 실패했습니다.', error);
    }
    
    return AppError.unknown('알 수 없는 오류가 발생했습니다.', error);
  }
}