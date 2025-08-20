import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:window_manager/window_manager.dart';
import 'python_service.dart';
import '../utils/logger.dart';

class AppLifecycleManager {
  static const double windowWidth = 1194;
  static const double windowHeight = 834;

  /// 앱 초기화 및 윈도우 설정
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(windowWidth, windowHeight),
      minimumSize: Size(windowWidth, windowHeight),
      maximumSize: Size(windowWidth, windowHeight),
      center: true,
      title: 'SIGMA',
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // Handle window close event
      await windowManager.setPreventClose(true);
      windowManager.addListener(AppWindowListener());
    });
  }

  /// Python 프로세스 정리
  static Future<void> cleanupPythonProcesses() async {
    print('Cleaning up Python processes...');
    
    // PythonService cleanup 호출
    await PythonService.cleanup();
    
    // 플랫폼별 강제 종료
    if (Platform.isWindows) {
      await _killWindowsPythonProcesses();
    } else {
      await _killUnixPythonProcesses();
    }
  }

  /// Windows에서 Python 프로세스 강제 종료
  static Future<void> _killWindowsPythonProcesses() async {
    try {
      await Process.run('taskkill', ['/F', '/IM', 'python.exe'], runInShell: true);
      await Process.run('taskkill', ['/F', '/IM', 'pythonw.exe'], runInShell: true);
    } catch (e) {
      Logger.error('Error killing Python processes on Windows', 'LIFECYCLE', e);
    }
  }

  /// Unix/Linux/macOS에서 Python 프로세스 강제 종료
  static Future<void> _killUnixPythonProcesses() async {
    try {
      await Process.run('pkill', ['-f', 'python'], runInShell: true);
    } catch (e) {
      Logger.error('Error killing Python processes on Unix', 'LIFECYCLE', e);
    }
  }

  /// 앱 종료 처리
  static Future<void> handleAppTermination() async {
    await cleanupPythonProcesses();
    await windowManager.setPreventClose(false);
    await windowManager.close();
    exit(0);
  }
}

/// 윈도우 이벤트 리스너
class AppWindowListener with WindowListener {
  @override
  Future<void> onWindowClose() async {
    print('Window is closing...');
    await AppLifecycleManager.handleAppTermination();
  }
}

/// 앱 생명주기 관리 Mixin
mixin AppLifecycleMixin<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  // WidgetsBindingObserver의 다른 메서드들 - 빈 구현
  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;

  @override
  Future<ui.AppExitResponse> didRequestAppExit() async => ui.AppExitResponse.exit;

  @override
  void didChangeViewFocus(ui.ViewFocusEvent event) {}

  @override
  void handleCancelBackGesture() {}

  @override
  void handleCommitBackGesture() {}

  @override
  bool handleStartBackGesture(dynamic backEvent) => false;

  @override
  void handleUpdateBackGestureProgress(dynamic backEvent) {}

  /// 앱이 종료될 때 호출
  void _handleAppDetached() {
    PythonService.cleanup();
    onAppDetached();
  }

  /// 앱이 일시정지될 때 호출
  void _handleAppPaused() {
    onAppPaused();
  }

  /// 앱이 재개될 때 호출
  void _handleAppResumed() {
    onAppResumed();
  }

  /// 앱이 비활성화될 때 호출
  void _handleAppInactive() {
    onAppInactive();
  }

  /// 앱이 숨겨질 때 호출
  void _handleAppHidden() {
    onAppHidden();
  }

  // 서브클래스에서 오버라이드 가능한 메서드들
  void onAppDetached() {}
  void onAppPaused() {}
  void onAppResumed() {}
  void onAppInactive() {}
  void onAppHidden() {}
}