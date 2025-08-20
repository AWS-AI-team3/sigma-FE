import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/env_service.dart';
import 'services/app_lifecycle_manager.dart';
import 'constants/app_constants.dart';
import 'themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/face_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  // 환경 변수 로드
  await EnvService.load();
  
  // 환경 변수 검증
  if (!EnvService.isConfigured) {
    print('Warning: Environment variables not properly configured. Please check .env file.');
  }
  
  // 앱 생명주기 관리자 초기화 (윈도우 설정 포함)
  await AppLifecycleManager.initialize();
  
  runApp(const SigmaApp());
}


class SigmaApp extends StatefulWidget {
  const SigmaApp({super.key});

  @override
  State<SigmaApp> createState() => _SigmaAppState();
}

class _SigmaAppState extends State<SigmaApp> with AppLifecycleMixin {
  @override
  void onAppDetached() {
    // 추가적인 앱 종료 처리가 필요하면 여기에 구현
  }
  
  @override
  void onAppPaused() {
    // 앱이 일시정지될 때의 처리
  }
  
  @override
  void onAppResumed() {
    // 앱이 재개될 때의 처리
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