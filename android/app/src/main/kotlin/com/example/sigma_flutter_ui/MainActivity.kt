package com.example.sigma_flutter_ui

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    /**
     * Flutter Engine 설정
     * GestureServiceModule 플러그인 등록
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // GestureServiceModule 플러그인 등록
        flutterEngine.plugins.add(GestureServiceModule())
    }
}
