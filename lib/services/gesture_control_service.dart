import 'package:flutter/services.dart';

/// 제스처 제어 서비스
///
/// Android Native Module과 통신하여 백그라운드 제스처 인식 서비스를 제어합니다.
///
/// 사용법:
/// ```dart
/// // 서비스 시작
/// await GestureControlService.startService();
///
/// // 서비스 중지
/// await GestureControlService.stopService();
/// ```
class GestureControlService {
  // Method Channel (Flutter ↔ Android 통신)
  static const MethodChannel _channel = MethodChannel('gesture_service');

  /// 백그라운드 제스처 인식 서비스 시작
  ///
  /// 주의: Accessibility Service와 오버레이 권한이 필요합니다.
  static Future<bool> startService() async {
    try {
      // 1. 오버레이 권한 확인
      final canDrawOverlays = await checkOverlayPermission();
      if (!canDrawOverlays) {
        print('오버레이 권한이 없습니다');
        return false;
      }

      // 2. Accessibility Service 확인
      final isAccessibilityEnabled = await checkAccessibilityEnabled();
      if (!isAccessibilityEnabled) {
        print('Accessibility Service가 활성화되지 않았습니다');
        return false;
      }

      // 3. 백그라운드 서비스 시작
      await _channel.invokeMethod('startGestureService');
      print('제스처 인식 서비스 시작됨');
      return true;
    } catch (e) {
      print('서비스 시작 실패: $e');
      return false;
    }
  }

  /// 백그라운드 제스처 인식 서비스 중지
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopGestureService');
      print('제스처 인식 서비스 중지됨');
    } catch (e) {
      print('서비스 중지 실패: $e');
    }
  }

  /// Accessibility Service 활성화 상태 확인
  static Future<bool> checkAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      print('Accessibility 상태 확인 실패: $e');
      return false;
    }
  }

  /// Accessibility 설정 화면 열기
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Accessibility 설정 열기 실패: $e');
    }
  }

  /// 오버레이 권한 확인
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays');
      return result ?? false;
    } catch (e) {
      print('오버레이 권한 확인 실패: $e');
      return false;
    }
  }

  /// 오버레이 권한 설정 화면 열기
  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (e) {
      print('오버레이 설정 열기 실패: $e');
    }
  }
}
