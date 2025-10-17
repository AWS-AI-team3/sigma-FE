import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GestureBrowserApp());
}

class GestureBrowserApp extends StatelessWidget {
  const GestureBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
