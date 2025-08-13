import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'routes/app_routes.dart';
import 'services/python_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  
  
  const double windowWidth = 480;
  const double windowHeight = 650;
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(windowWidth, windowHeight),
    minimumSize: Size(windowWidth, windowHeight),
    maximumSize: Size(windowWidth, windowHeight),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'SIGMA - Smart Interactive Gesture Management Assistant',
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
        print('Error killing Python processes: $e');
      }
    } else {
      try {
        await Process.run('pkill', ['-f', 'python'], runInShell: true);
      } catch (e) {
        print('Error killing Python processes: $e');
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
    return MaterialApp(
      title: 'SIGMA - Smart Interactive Gesture Management Assistant',
      theme: ThemeData(
        fontFamily: GoogleFonts.roboto().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}