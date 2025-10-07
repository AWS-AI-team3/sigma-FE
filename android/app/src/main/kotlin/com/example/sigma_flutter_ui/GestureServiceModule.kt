package com.example.sigma_flutter_ui

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter와 Android Native를 연결하는 Method Channel
 *
 * 역할:
 * 1. Flutter에서 백그라운드 서비스 시작/중지
 * 2. Accessibility Service 상태 확인
 * 3. 권한 설정 화면 열기
 */
class GestureServiceModule : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    companion object {
        private const val CHANNEL_NAME = "gesture_service"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Flutter에서 호출하는 메서드 처리
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // 백그라운드 서비스 시작
            "startGestureService" -> {
                startGestureService()
                result.success(true)
            }

            // 백그라운드 서비스 중지
            "stopGestureService" -> {
                stopGestureService()
                result.success(true)
            }

            // Accessibility Service 활성화 상태 확인
            "isAccessibilityEnabled" -> {
                val isEnabled = isAccessibilityServiceEnabled()
                result.success(isEnabled)
            }

            // Accessibility 설정 화면 열기
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(null)
            }

            // 오버레이 권한 확인
            "canDrawOverlays" -> {
                val canDraw = Settings.canDrawOverlays(context)
                result.success(canDraw)
            }

            // 오버레이 권한 설정 화면 열기
            "openOverlaySettings" -> {
                openOverlaySettings()
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * 백그라운드 서비스 시작
     */
    private fun startGestureService() {
        val intent = Intent(context, GestureBackgroundService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    /**
     * 백그라운드 서비스 중지
     */
    private fun stopGestureService() {
        val intent = Intent(context, GestureBackgroundService::class.java)
        context.stopService(intent)
    }

    /**
     * Accessibility Service가 활성화되어 있는지 확인
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${context.packageName}/.AccessibilityGestureService"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(serviceName) == true
    }

    /**
     * Accessibility 설정 화면 열기
     */
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    /**
     * 오버레이 권한 설정 화면 열기
     */
    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:${context.packageName}")
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        }
    }
}
