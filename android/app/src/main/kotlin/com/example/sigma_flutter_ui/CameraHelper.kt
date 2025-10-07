package com.example.sigma_flutter_ui

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 백그라운드 카메라 캡처 및 MediaPipe 처리를 위한 헬퍼 클래스
 */
class CameraHelper(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val handLandmarker: HandLandmarker,
    private val onResultCallback: (com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult?) -> Unit
) {
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var camera: Camera? = null
    private var frameTimestamp: Long = 0

    @SuppressLint("UnsafeOptInUsageError")
    fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            // ImageAnalysis 설정 - 손 추적용
            val imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setTargetRotation(0)
                .build()

            imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
                processImage(imageProxy)
            }

            try {
                cameraProvider.unbindAll()

                // 전면 카메라 사용
                camera = cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_FRONT_CAMERA,
                    imageAnalysis
                )

                Log.d("CameraHelper", "Camera started successfully")
            } catch (e: Exception) {
                Log.e("CameraHelper", "Camera initialization failed", e)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun processImage(imageProxy: ImageProxy) {
        try {
            // ImageProxy를 Bitmap으로 변환
            val bitmap = imageProxy.toBitmap()

            // Bitmap을 MediaPipe MPImage로 변환
            val mpImage = BitmapImageBuilder(bitmap).build()

            // 타임스탬프 증가
            frameTimestamp += 33  // ~30 FPS

            // MediaPipe로 손 추적 수행 (VIDEO 모드)
            val result = handLandmarker.detectForVideo(mpImage, frameTimestamp)

            // 결과 콜백 호출
            CoroutineScope(Dispatchers.Main).launch {
                onResultCallback(result)
            }
        } catch (e: Exception) {
            Log.e("CameraHelper", "Error processing image", e)
            onResultCallback(null)
        } finally {
            imageProxy.close()
        }
    }

    fun stopCamera() {
        camera = null
        cameraExecutor.shutdown()
        Log.d("CameraHelper", "Camera stopped")
    }
}
