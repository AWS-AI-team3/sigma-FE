package com.example.sigma_flutter_ui

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent

/**
 * 다른 앱에 터치 이벤트를 보내는 Accessibility Service
 *
 * 역할:
 * 1. 현재 커서 위치 저장
 * 2. 핀치 제스처 감지 시 해당 위치 터치 실행
 * 3. 드래그 제스처 지원
 *
 * 주의: 사용자가 설정에서 수동으로 활성화해야 합니다
 * (설정 → 접근성 → SIGMA → 활성화)
 */
class AccessibilityGestureService : AccessibilityService() {

    companion object {
        // 서비스 인스턴스 (Static 싱글톤)
        private var instance: AccessibilityGestureService? = null

        // 현재 커서 위치
        private var currentCursorX = 0f
        private var currentCursorY = 0f

        /**
         * 커서 위치 업데이트 (GestureBackgroundService에서 호출)
         */
        fun updateCursorPosition(x: Float, y: Float) {
            currentCursorX = x
            currentCursorY = y
        }

        /**
         * 현재 커서 위치에서 터치 실행 (GestureBackgroundService에서 호출)
         */
        fun performTouchAtCursor() {
            instance?.executeTouchAtCursor()
        }

        /**
         * 드래그 실행 (시작 → 끝 위치)
         */
        fun performDrag(startX: Float, startY: Float, endX: Float, endY: Float) {
            instance?.executeDrag(startX, startY, endX, endY)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // YouTube 앱 감지 등 (선택사항)
        // 현재는 모든 앱에서 동작
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    /**
     * 현재 커서 위치에서 터치 실행 (Private 메서드)
     */
    private fun executeTouchAtCursor() {
        // 터치 Path 생성 (점 클릭)
        val path = Path().apply {
            moveTo(currentCursorX, currentCursorY)
        }

        // Gesture 빌더
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))  // 100ms 터치
            .build()

        // 터치 실행
        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                // 터치 성공
                println("Touch executed at ($currentCursorX, $currentCursorY)")
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                // 터치 실패
                println("Touch cancelled")
            }
        }, null)
    }

    /**
     * 드래그 실행 (Private 메서드)
     *
     * @param startX 시작 X 좌표
     * @param startY 시작 Y 좌표
     * @param endX 끝 X 좌표
     * @param endY 끝 Y 좌표
     */
    private fun executeDrag(startX: Float, startY: Float, endX: Float, endY: Float) {
        // 드래그 Path 생성 (선)
        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }

        // Gesture 빌더
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 300))  // 300ms 드래그
            .build()

        // 드래그 실행
        dispatchGesture(gesture, null, null)
    }
}
