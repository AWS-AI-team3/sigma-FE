package com.example.sigma_flutter_ui

import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageView

/**
 * 다른 앱 위에 커서를 표시하는 오버레이 관리자
 *
 * 역할:
 * 1. WindowManager로 오버레이 View 생성
 * 2. 엄지 위치에 따라 커서 이동
 * 3. 60 FPS로 부드러운 움직임
 */
class CursorOverlayManager(private val context: Context) {

    // WindowManager (시스템 서비스)
    private val windowManager: WindowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    // 커서 View (동그라미 이미지)
    private var cursorView: ImageView? = null

    // 오버레이 표시 상태
    private var isShowing = false

    init {
        createCursorView()
    }

    /**
     * 커서 View 생성 및 오버레이 추가
     */
    private fun createCursorView() {
        // 커서 이미지 View 생성
        cursorView = ImageView(context).apply {
            // TODO: 커스텀 커서 이미지 사용
            // setImageResource(R.drawable.cursor_pointer)

            // 임시: 기본 아이콘 사용
            setImageResource(android.R.drawable.presence_online)
        }

        // 오버레이 레이아웃 파라미터 설정
        val params = WindowManager.LayoutParams(
            48,  // 커서 크기: 48dp
            48,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,  // 다른 앱 위에 표시
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or      // 터치 이벤트 무시
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or      // 터치 이벤트 통과
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,     // 화면 밖으로 나갈 수 있음
            PixelFormat.TRANSLUCENT  // 투명도 지원
        )
        params.gravity = Gravity.TOP or Gravity.START

        // WindowManager에 커서 View 추가
        windowManager.addView(cursorView, params)
        isShowing = true
    }

    /**
     * 커서 위치 업데이트
     *
     * @param x 화면 X 좌표
     * @param y 화면 Y 좌표
     */
    fun updatePosition(x: Float, y: Float) {
        if (!isShowing || cursorView == null) return

        cursorView?.let { view ->
            val params = view.layoutParams as WindowManager.LayoutParams

            // 커서 중앙 정렬 (커서 크기의 절반만큼 이동)
            params.x = (x - 24).toInt()  // 24 = 48 / 2
            params.y = (y - 24).toInt()

            // UI 업데이트 (60 FPS로 부드럽게 이동)
            windowManager.updateViewLayout(view, params)
        }
    }

    /**
     * 커서 숨기기
     */
    fun hide() {
        cursorView?.visibility = android.view.View.GONE
    }

    /**
     * 커서 표시
     */
    fun show() {
        cursorView?.visibility = android.view.View.VISIBLE
    }

    /**
     * 오버레이 제거 (서비스 종료 시 호출)
     */
    fun destroy() {
        if (isShowing && cursorView != null) {
            windowManager.removeView(cursorView)
            cursorView = null
            isShowing = false
        }
    }
}
