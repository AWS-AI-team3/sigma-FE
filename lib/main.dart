import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/python_service.dart';
import 'services/env_service.dart';
import 'constants/app_constants.dart';
import 'themes/app_theme.dart';
import 'utils/logger.dart';
import 'providers/auth_provider.dart';
import 'providers/face_provider.dart';
import 'providers/settings_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드
  await EnvService.load();
  
  // 환경 변수 검증
  if (!EnvService.isConfigured) {
    print('Warning: Environment variables not properly configured. Please check .env file.');
  }
  
  await windowManager.ensureInitialized();
  
  
  const double windowWidth = 1194;
  const double windowHeight = 834;
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(windowWidth, windowHeight),
    minimumSize: Size(windowWidth, windowHeight),
    maximumSize: Size(windowWidth, windowHeight),
    center: true,
    title: 'SIGMA',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    
    // Handle window close event
    await windowManager.setPreventClose(true);
    windowManager.addListener(AppWindowListener());
  });
  
  runApp(const SigmaApp());
}

class AppWindowListener with WindowListener {
  @override
  Future<void> onWindowClose() async {
    // Clean up Python processes before closing
    print('Window is closing, cleaning up Python processes...');
    await PythonService.cleanup();
    
    // Force kill any remaining Python processes
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/IM', 'python.exe'], runInShell: true);
        await Process.run('taskkill', ['/F', '/IM', 'pythonw.exe'], runInShell: true);
      } catch (e) {
        Logger.error('Error killing Python processes', 'MAIN', e);
      }
    } else {
      try {
        await Process.run('pkill', ['-f', 'python'], runInShell: true);
      } catch (e) {
        Logger.error('Error killing Python processes', 'MAIN', e);
      }
    }
    
    // Now allow the window to close
    await windowManager.setPreventClose(false);
    await windowManager.close();
    exit(0);
  }
}

class SigmaApp extends StatefulWidget {
  const SigmaApp({super.key});

  @override
  State<SigmaApp> createState() => _SigmaAppState();
}

class _SigmaAppState extends State<SigmaApp> with WidgetsBindingObserver {
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
        // App is being terminated
        PythonService.cleanup();
        break;
      case AppLifecycleState.paused:
        // App is paused (minimized)
        break;
      case AppLifecycleState.resumed:
        // App is resumed
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FaceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}