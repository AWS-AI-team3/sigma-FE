package com.example.sigma_flutter_ui

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import kotlin.math.sqrt

/**
 * 백그라운드에서 제스처를 인식하는 Foreground Service
 *
 * 역할:
 * 1. 카메라로 손 추적 (MediaPipe)
 * 2. 엄지 위치 추출
 * 3. CursorOverlayManager로 커서 표시
 * 4. 제스처 감지 시 AccessibilityService로 터치 실행
 */
class GestureBackgroundService : Service(), LifecycleOwner {

    // Lifecycle for CameraX
    private val lifecycleRegistry = LifecycleRegistry(this)

    // 커서 오버레이 관리자
    private var cursorOverlay: CursorOverlayManager? = null

    // MediaPipe 손 추적기
    private var handLandmarker: HandLandmarker? = null

    // 카메라 헬퍼
    private var cameraHelper: CameraHelper? = null

    // 서비스 실행 상태
    private var isRunning = false

    // 핀치 제스처 감지를 위한 임계값
    private val pinchThreshold = 0.06f

    // 핀치 상태 추적
    private var isPinching = false

    companion object {
        const val CHANNEL_ID = "GestureServiceChannel"
        const val NOTIFICATION_ID = 1
        private const val TAG = "GestureService"
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override fun onCreate() {
        super.onCreate()

        lifecycleRegistry.currentState = Lifecycle.State.CREATED

        // Foreground Service 시작 (백그라운드에서 계속 실행되도록)
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // 커서 오버레이 초기화
        cursorOverlay = CursorOverlayManager(this)

        // MediaPipe 초기화
        initializeMediaPipe()

        // 카메라 시작
        startBackgroundCamera()

        lifecycleRegistry.currentState = Lifecycle.State.STARTED

        isRunning = true
        Log.d(TAG, "Service created and started")
    }

    /**
     * MediaPipe HandLandmarker 초기화
     */
    private fun initializeMediaPipe() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.VIDEO)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.6f)
                .setMinTrackingConfidence(0.7f)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(this, options)
            Log.d(TAG, "MediaPipe initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MediaPipe", e)
        }
    }

    /**
     * 백그라운드 카메라 시작
     */
    private fun startBackgroundCamera() {
        val landmarker = handLandmarker ?: return

        cameraHelper = CameraHelper(
            context = this,
            lifecycleOwner = this,
            handLandmarker = landmarker,
            onResultCallback = { result ->
                processHandLandmarks(result)
            }
        )

        cameraHelper?.startCamera()
        Log.d(TAG, "Camera started")
    }

    /**
     * MediaPipe 결과 처리 - 손 랜드마크에서 엄지 위치 추출 및 제스처 감지
     */
    private fun processHandLandmarks(result: com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult?) {
        if (result == null || result.landmarks().isEmpty()) {
            return
        }

        val landmarks = result.landmarks()[0]  // 첫 번째 손만 처리

        // 엄지 끝 (landmark index 4)
        val thumbTip = landmarks[4]

        // 화면 좌표로 변환 (0.0~1.0 → 실제 픽셀)
        val screenWidth = resources.displayMetrics.widthPixels.toFloat()
        val screenHeight = resources.displayMetrics.heightPixels.toFloat()

        val thumbX = thumbTip.x() * screenWidth
        val thumbY = thumbTip.y() * screenHeight

        // 커서 위치 업데이트
        updateCursorPosition(thumbX, thumbY)

        // Accessibility Service에도 커서 위치 전달
        AccessibilityGestureService.updateCursorPosition(thumbX, thumbY)

        // 제스처 분류 (엄지+검지 핀치)
        val gesture = classifyGesture(landmarks)
        if (gesture != null) {
            onGestureDetected(gesture)
        }
    }

    /**
     * 제스처 분류 - 엄지와 검지 끝의 거리로 핀치 감지
     */
    private fun classifyGesture(landmarks: List<com.google.mediapipe.tasks.components.containers.NormalizedLandmark>): String? {
        val thumbTip = landmarks[4]   // 엄지 끝
        val indexTip = landmarks[8]   // 검지 끝

        // 3D 유클리드 거리 계산
        val dx = thumbTip.x() - indexTip.x()
        val dy = thumbTip.y() - indexTip.y()
        val dz = thumbTip.z() - indexTip.z()
        val distance = sqrt(dx * dx + dy * dy + dz * dz)

        // 핀치 감지
        val isPinchingNow = distance < pinchThreshold

        if (isPinchingNow && !isPinching) {
            // 핀치 시작
            isPinching = true
            return "thumb_index_pinch"
        } else if (!isPinchingNow && isPinching) {
            // 핀치 종료
            isPinching = false
        }

        return null
    }

    /**
     * 알림 채널 생성 (Android 8.0 이상 필수)
     */
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "제스처 인식 서비스",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "백그라운드에서 제스처를 인식합니다"
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    /**
     * Foreground Service 알림 생성
     */
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SIGMA 제스처 제어")
            .setContentText("백그라운드에서 제스처를 인식하고 있습니다")
            .setSmallIcon(android.R.drawable.ic_menu_camera)  // TODO: 커스텀 아이콘으로 변경
            .setContentIntent(pendingIntent)
            .setOngoing(true)  // 사용자가 삭제할 수 없도록
            .build()
    }

    /**
     * 엄지 위치 업데이트 (MediaPipe 콜백에서 호출)
     *
     * @param x 화면 X 좌표
     * @param y 화면 Y 좌표
     */
    fun updateCursorPosition(x: Float, y: Float) {
        cursorOverlay?.updatePosition(x, y)
    }

    /**
     * 제스처 감지 시 호출 (MediaPipe 콜백에서 호출)
     *
     * @param gesture 제스처 타입 (예: "thumb_index_pinch")
     */
    fun onGestureDetected(gesture: String) {
        when (gesture) {
            "thumb_index_pinch" -> {
                // Accessibility Service로 터치 실행
                AccessibilityGestureService.performTouchAtCursor()
            }
            // TODO: 다른 제스처 추가
        }
    }

    override fun onDestroy() {
        super.onDestroy()

        // 카메라 정지
        cameraHelper?.stopCamera()
        cameraHelper = null

        // MediaPipe 정리
        handLandmarker?.close()
        handLandmarker = null

        // 커서 오버레이 제거
        cursorOverlay?.destroy()
        cursorOverlay = null

        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED

        isRunning = false
        Log.d(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
