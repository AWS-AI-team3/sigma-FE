//
//  GestureRecognitionManager.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import Vision
import AVFoundation
import Combine

final class GestureRecognitionManager: NSObject, ObservableObject {
    @Published var thumbPosition: CGPoint = .zero
    @Published var screenThumbPosition: CGPoint = .zero // 화면 전체 좌표계의 위치
    @Published var isIndexFingerNearThumb: Bool = false
    @Published var isPinching: Bool = false
    @Published var shouldClick: Bool = false
    @Published var isRunning: Bool = false
    @Published var handConfidence: Float = 0.0
    @Published var gestureStability: Float = 0.0
    @Published var debugInfo: String = "" // 디버깅 정보
    @Published var frameRate: Double = 0.0 // 실제 처리 프레임율
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // 고성능 처리를 위한 멀티 큐 시스템
    private let visionQueue = DispatchQueue(label: "gesture.vision.queue", qos: .userInteractive, attributes: .concurrent)
    private let processingQueue = DispatchQueue(label: "gesture.processing.queue", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "gesture.session.queue", qos: .userInteractive)
    
    // 성능 모니터링
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsUpdateTimer: Timer?
    
    // 디바이스 방향 추적
    private var deviceOrientation: UIDeviceOrientation = .landscapeLeft
    private var screenSize: CGSize = CGSize(width: 1024, height: 768) // Default iPad size, will be updated from context
    
    // 제스처 활성 영역 패딩 (정규화 비율, 0.0~0.49 권장)
    private var activePaddingX: CGFloat = 0.20 // 좌우 가장자리 제외 비율
    private var activePaddingY: CGFloat = 0.20 // 상하 가장자리 제외 비율

    // 가장자리 민감도 완화를 위한 이징 강도 (0.0 ~ 1.0)
    private var edgeEasingStrength: CGFloat = 0.5

    // 전체 민감도 조절을 위한 감마 값 (1.0 = 기본, >1.0 = 덜 민감, <1.0 = 더 민감)
    private var sensitivityGamma: CGFloat = 1.3

    // Vision 핸들러 재사용 및 적응형 처리 제어
    private let sequenceHandler = VNSequenceRequestHandler()
    private var skipCounter = 0
    private var dynamicSkip = 0
    private var avgProcessingTime: Double = 0.0
    private var adjustCounter = 0
    
    // 고성능 정확도 향상을 위한 속성들
    private var positionHistory: [CGPoint] = []
    private var distanceHistory: [Double] = []
    private var confidenceHistory: [Float] = []
    private let historySize = 5 // iPad 성능을 활용해 더 정확한 스무딩
    private var lastValidPosition: CGPoint = .zero
    private var consecutivePinchFrames = 0
    private var consecutiveReleaseFrames = 0
    private let stabilityThreshold = 2
    
    // 적응형 임계값들 - iPad Pro 성능에 최적화
    private var adaptivePinchThreshold: Double = 0.025 // 더 정밀한 감지
    private var adaptiveReleaseThreshold: Double = 0.045
    private var minConfidenceThreshold: Float = 0.4 // 낮춰서 더 민감하게
    
    // 고급 필터링
    private var kalmanFilter = KalmanFilter()
    private var gestureBuffer: CircularBuffer<GestureData> = CircularBuffer(capacity: 10)
    
    // 멀티스레딩 최적화
    private let semaphore = DispatchSemaphore(value: 1)
    private var isProcessingFrame = false
    
    private lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        if let supported = VNDetectHumanHandPoseRequest.supportedRevisions.max() {
            request.revision = supported
        } else {
            request.revision = VNDetectHumanHandPoseRequestRevision1
        }
        return request
    }()
    
    // 고성능 요청 풀링
    private var requestPool: [VNDetectHumanHandPoseRequest] = []
    private let maxPoolSize = 3
    
    override init() {
        super.init()
        
        // 요청 풀 초기화
        for _ in 0..<maxPoolSize {
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1
            if let supported = VNDetectHumanHandPoseRequest.supportedRevisions.max() {
                request.revision = supported
            } else {
                request.revision = VNDetectHumanHandPoseRequestRevision1
            }
            requestPool.append(request)
        }
        
        // FPS 모니터링 타이머 시작
        startFPSMonitoring()
        
        // Neural Engine 최적화 설정
        optimizeForNeuralEngine()
    }
    
    deinit {
        fpsUpdateTimer?.invalidate()
    }
    
    // MARK: - 성능 최적화 기능들
    
    private func startFPSMonitoring() {
        fpsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.frameRate = Double(self.frameCount)
                self.frameCount = 0
            }
        }
    }
    
    private func optimizeForNeuralEngine() {
        // Neural Engine 최적화를 위한 설정
        for request in requestPool {
            // iOS 13+ Neural Engine 최적화
            if #available(iOS 13.0, *) {
                request.usesCPUOnly = false // Neural Engine 사용
            }
        }
    }
    
    // 제스처 보정 기능 추가 - 고성능 버전
    func calibrateGestures() {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 사용자별 제스처 보정 - 더 정밀하게
            self.adaptivePinchThreshold = 0.025
            self.adaptiveReleaseThreshold = 0.045
            
            // 히스토리 초기화
            self.positionHistory.removeAll()
            self.distanceHistory.removeAll()
            self.confidenceHistory.removeAll()
            self.consecutivePinchFrames = 0
            self.consecutiveReleaseFrames = 0
            
            // 칼만 필터 재설정
            self.kalmanFilter = KalmanFilter(processNoise: 0.005, measurementNoise: 0.05)
            
            print("제스처 인식이 고성능 모드로 보정되었습니다.")
        }
    }
    
    // 환경 설정에 따른 최적화
    func optimizeForEnvironment(lightingCondition: LightingCondition = .normal) {
        switch lightingCondition {
        case .bright:
            minConfidenceThreshold = 0.6
        case .dim:
            minConfidenceThreshold = 0.4
        case .normal:
            minConfidenceThreshold = 0.5
        }
    }
    
    // 디바이스 방향 업데이트
    func updateDeviceOrientation(_ orientation: UIDeviceOrientation) {
        deviceOrientation = orientation
    }
    
    // 화면 크기 업데이트
    func updateScreenSize(_ size: CGSize) {
        screenSize = size
        print("화면 크기 업데이트: \(size)")
    }
    
    // 제스처 활성 영역 패딩 설정 (0.0 ~ 0.49 권장)
    func setActiveRegionPadding(xFraction: CGFloat, yFraction: CGFloat) {
        // 안전 범위로 클램핑 (0.0 ~ 0.49)
        let clampedX = max(0.0, min(0.49, xFraction))
        let clampedY = max(0.0, min(0.49, yFraction))
        activePaddingX = clampedX
        activePaddingY = clampedY
        print("활성 제스처 영역 패딩 설정: x=\(clampedX), y=\(clampedY)")
    }
    
    // 가장자리 민감도 이징 강도 설정 (0.0 ~ 1.0)
    func setEdgeEasingStrength(_ strength: CGFloat) {
        let clamped = max(0.0, min(1.0, strength))
        edgeEasingStrength = clamped
        print("엣지 이징 강도 설정: \(clamped)")
    }
    
    // 전체 민감도 감마 설정 (권장 범위 0.7 ~ 2.5)
    func setSensitivityGamma(_ gamma: CGFloat) {
        // 0.3~3.0 사이로 제한
        let clamped = max(0.3, min(3.0, gamma))
        sensitivityGamma = clamped
        print("민감도 감마 설정: \(clamped)")
    }
    
    // 현재 화면 크기로 자동 업데이트 (deprecated - 대신 updateScreenSize(_:)를 view context에서 호출)
    @available(*, deprecated, message: "Use updateScreenSize(_:) with screen size from view context instead")
    func updateToCurrentScreenSize() {
        // This method is deprecated and should not be used
        // Instead, call updateScreenSize(_:) from your view with the appropriate screen size
        print("⚠️ updateToCurrentScreenSize() is deprecated. Please use updateScreenSize(_:) from your view context.")
    }
    
    func startGestureRecognition() {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }
    
    func stopGestureRecognition() {
        captureSession?.stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        // iPad Pro의 성능을 최대한 활용하는 설정
        captureSession.beginConfiguration()
        
        // 최고 화질 설정 - iPad Pro의 카메라 성능 활용
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720 // 720p로 고화질과 성능 균형
        } else {
            captureSession.sessionPreset = .high
        }
        
        // 멀티스레딩 최적화
        captureSession.automaticallyConfiguresApplicationAudioSession = false
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("카메라를 찾을 수 없습니다.")
            captureSession.commitConfiguration()
            return
        }
        
        // 카메라 설정 최적화
        do {
            try camera.lockForConfiguration()
            
            // iPad Pro 120Hz 디스플레이에 맞춘 고속 프레임율
            // 카메라는 최대 60fps, 하지만 처리는 120Hz 디스플레이에 맞춰 최적화
            let supportedRanges = camera.activeFormat.videoSupportedFrameRateRanges
            
            if let highestRange = supportedRanges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) {
                let targetFrameRate = min(highestRange.maxFrameRate, 60.0) // 최대 60fps
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate))
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate))
                print("카메라 프레임율 설정: \(targetFrameRate)fps")
            }
            
            // 자동 초점 설정
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            
            // 자동 노출 설정
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            
            camera.unlockForConfiguration()
        } catch {
            print("카메라 설정 최적화 오류: \(error)")
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput?.alwaysDiscardsLateVideoFrames = true // 지연 프레임 버리기
            videoOutput?.setSampleBufferDelegate(self, queue: sessionQueue)
            
            if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                
                // 비디오 연결 방향 설정 (동적으로 방향 결정)
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        let videoOrientation: AVCaptureVideoOrientation
                        switch deviceOrientation {
                        case .landscapeLeft:
                            videoOrientation = .landscapeRight
                        case .landscapeRight:
                            videoOrientation = .landscapeLeft
                        case .portrait:
                            videoOrientation = .portrait
                        case .portraitUpsideDown:
                            videoOrientation = .portraitUpsideDown
                        default:
                            videoOrientation = .landscapeRight // 기본값
                        }
                        connection.videoOrientation = videoOrientation
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }
            
            // 설정 완료 후 커밋
            captureSession.commitConfiguration()
            
            // 이제 세션 시작
            captureSession.startRunning()
            
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = true
            }
        } catch {
            print("카메라 설정 오류: \(error)")
            captureSession.commitConfiguration() // 오류 발생시에도 설정 커밋
        }
    }

    private func adjustSessionPreset(forAverageProcessingTime t: Double) {
        guard let session = captureSession else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if t > 0.030 { // 처리 부하가 높음
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }
        } else {
            if session.canSetSessionPreset(.hd1280x720) {
                session.sessionPreset = .hd1280x720
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension GestureRecognitionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 프레임 스키핑으로 성능 최적화
        guard semaphore.wait(timeout: .now()) == .success else { return }
        defer { semaphore.signal() }
        
        guard !isProcessingFrame else { return }
        isProcessingFrame = true
        
        // 적응형 프레임 스킵: 처리 부하가 높을 때 일부 프레임 건너뛰기
        if dynamicSkip > 0 {
            skipCounter += 1
            if skipCounter <= dynamicSkip {
                isProcessingFrame = false
                return
            } else {
                skipCounter = 0
            }
        }
        
        // FPS 카운팅
        frameCount += 1
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        // 요청 풀에서 사용 가능한 요청 가져오기
        let request = requestPool.first ?? handPoseRequest
        
        // 비동기 처리로 메인 스레드 블로킹 방지
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Vision ROI를 활성 제스처 영역으로 제한 (정규화 좌표, 좌하단 원점)
            let roiMinX = self.activePaddingX
            let roiMinY = self.activePaddingY
            let roiWidth = max(0.0, 1.0 - self.activePaddingX * 2.0)
            let roiHeight = max(0.0, 1.0 - self.activePaddingY * 2.0)
            request.regionOfInterest = CGRect(x: roiMinX, y: roiMinY, width: roiWidth, height: roiHeight)

            let start = CACurrentMediaTime()
            do {
                try self.sequenceHandler.perform([request], on: imageBuffer, orientation: .up)
                if let observation = request.results?.first {
                    self.processHandPose(observation)
                }
            } catch {
                print("손 인식 처리 오류: \(error)")
            }
            let elapsed = CACurrentMediaTime() - start
            // EWMA로 평균 처리시간 갱신
            let alpha = 0.2
            self.avgProcessingTime = (1 - alpha) * self.avgProcessingTime + alpha * elapsed
            // 처리시간에 따른 동적 스킵 조정
            if self.avgProcessingTime > 0.030 { // 30ms 이상이면 스킵 증가
                self.dynamicSkip = min(self.dynamicSkip + 1, 3)
            } else if self.avgProcessingTime < 0.015 { // 15ms 이하이면 스킵 감소
                self.dynamicSkip = max(self.dynamicSkip - 1, 0)
            }
            // 주기적으로 카메라 프리셋 조정
            self.adjustCounter += 1
            if self.adjustCounter >= 30 {
                self.adjustCounter = 0
                let avg = self.avgProcessingTime
                self.sessionQueue.async { [weak self] in
                    self?.adjustSessionPreset(forAverageProcessingTime: avg)
                }
            }

            DispatchQueue.main.async {
                self.isProcessingFrame = false
            }
        }
    }
    
    private func processHandPose(_ observation: VNHumanHandPoseObservation) {
        let currentTime = CACurrentMediaTime()
        
        guard let thumbTip = try? observation.recognizedPoint(.thumbTip),
              let indexTip = try? observation.recognizedPoint(.indexTip),
              let thumbIP = try? observation.recognizedPoint(.thumbIP),
              let indexPIP = try? observation.recognizedPoint(.indexPIP),
              let wrist = try? observation.recognizedPoint(.wrist) // 손목 추가로 안정성 향상
        else { return }
        
        // 적응형 신뢰도 임계값 - 더 정교하게 조정
        let dynamicConfidence = adaptiveDynamicConfidence(baseConfidence: minConfidenceThreshold)
        
        guard thumbTip.confidence > dynamicConfidence,
              indexTip.confidence > dynamicConfidence,
              thumbIP.confidence > dynamicConfidence * 0.7,
              indexPIP.confidence > dynamicConfidence * 0.7 else { return }
        
        // 좌표 변환 - 캐시된 변환 행렬 사용
        let thumbPoint = transformCoordinate(thumbTip.location, for: deviceOrientation)
        let indexPoint = transformCoordinate(indexTip.location, for: deviceOrientation)
        
        // 칼만 필터를 통한 고급 스무딩
        let filteredThumbPoint = kalmanFilter.update(measurement: thumbPoint, timestamp: currentTime)
        
        // 벡터 연산을 통한 고속 거리 계산
        let deltaX = filteredThumbPoint.x - indexPoint.x
        let deltaY = filteredThumbPoint.y - indexPoint.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        
        // 손가락 각도와 손목 상대 위치를 통한 제스처 검증
        let thumbAngle = calculateFingerAngle(tip: thumbTip, pip: thumbIP)
        let indexAngle = calculateFingerAngle(tip: indexTip, pip: indexPIP)
        let wristDistance = calculateWristDistance(wrist: wrist, thumb: thumbTip, index: indexTip)
        
        // 고급 제스처 데이터 생성
        let gestureData = GestureData(
            thumbPosition: filteredThumbPoint,
            indexPosition: indexPoint,
            distance: distance,
            confidence: (thumbTip.confidence + indexTip.confidence) / 2,
            timestamp: currentTime,
            thumbAngle: thumbAngle,
            indexAngle: indexAngle
        )
        
        // 원형 버퍼에 데이터 저장
        gestureBuffer.append(gestureData)
        
        // 고급 필터링 및 예측
        let (smoothedPosition, smoothedDistance, stability) = advancedFiltering()
        let handConfidence = gestureData.confidence
        
        // 기계 학습 기반 적응형 임계값
        adaptiveThresholdLearning(confidence: handConfidence, stability: stability, wristDistance: wristDistance)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.thumbPosition = smoothedPosition
            self.screenThumbPosition = self.normalizedToScreenCoordinate(smoothedPosition)
            self.handConfidence = handConfidence
            self.gestureStability = stability
            
            // 디버깅 정보 업데이트
            self.debugInfo = """
            Raw Vision: (\(String(format: "%.3f", thumbTip.location.x)), \(String(format: "%.3f", thumbTip.location.y)))
            Transformed: (\(String(format: "%.3f", thumbPoint.x)), \(String(format: "%.3f", thumbPoint.y)))
            Smoothed: (\(String(format: "%.3f", smoothedPosition.x)), \(String(format: "%.3f", smoothedPosition.y)))
            Screen: (\(String(format: "%.0f", self.screenThumbPosition.x)), \(String(format: "%.0f", self.screenThumbPosition.y)))
            Screen Size: \(String(format: "%.0f", self.screenSize.width))x\(String(format: "%.0f", self.screenSize.height))
            Orientation: \(self.deviceOrientation.rawValue)
            Active Padding: x=\(String(format: "%.2f", self.activePaddingX)), y=\(String(format: "%.2f", self.activePaddingY))
            Active Region: [\(String(format: "%.2f",  self.activePaddingX))~\(String(format: "%.2f", 1 - self.activePaddingX)), \(String(format: "%.2f", self.activePaddingY))~\(String(format: "%.2f", 1 - self.activePaddingY))]
            Sensitivity Gamma: \(String(format: "%.2f", self.sensitivityGamma))
            """
            
            // 향상된 핀치 감지 로직
            self.detectPinchGesture(distance: smoothedDistance, 
                                  thumbAngle: thumbAngle, 
                                  indexAngle: indexAngle,
                                  confidence: handConfidence)
        }
    }
    
    // MARK: - Helper Methods for Accuracy Improvement
    
    private func transformCoordinate(_ point: CGPoint, for orientation: UIDeviceOrientation) -> CGPoint {
        // Vision 좌표계: (0,0)이 좌하단, (1,1)이 우상단
        // 화면 좌표계: (0,0)이 좌상단, (1,1)이 우하단
        // iPad 가로 모드에서 카메라가 상단 중앙에 위치
        
        switch orientation {
        case .landscapeLeft:
            // 가로(홈 버튼/전원 버튼이 오른쪽) - 축을 교차하지 않고 그대로 사용
            // 손 위/아래 -> 화면 위/아래, 손 좌/우 -> 화면 좌/우
            return CGPoint(
                x: point.x,
                y: 1 - point.y
            )
        case .landscapeRight:
            // 가로 반대 방향 - 좌우만 반전하여 일관성 유지
            return CGPoint(
                x: 1 - point.x,
                y: 1 - point.y
            )
        case .portrait:
            // 세로 - 기본 매핑
            return CGPoint(
                x: point.x,
                y: 1 - point.y
            )
        case .portraitUpsideDown:
            // 세로 뒤집힘 - 상하는 그대로, 좌우 반전
            return CGPoint(
                x: 1 - point.x,
                y: point.y
            )
        default:
            // 기본값: 세로와 동일한 매핑
            return CGPoint(
                x: point.x,
                y: 1 - point.y
            )
        }
    }
    
    // 정규화된 좌표를 화면 좌표로 변환
    private func normalizedToScreenCoordinate(_ normalizedPoint: CGPoint) -> CGPoint {
        // 1) 정규화 좌표를 활성 영역으로 클램핑 후 0~1로 리매핑
        let minX = activePaddingX
        let maxX = 1.0 - activePaddingX
        let minY = activePaddingY
        let maxY = 1.0 - activePaddingY
        let width = max(maxX - minX, 0.001)
        let height = max(maxY - minY, 0.001)

        // 활성 영역 내로 클램핑
        let clampedXInActive = max(minX, min(maxX, normalizedPoint.x))
        let clampedYInActive = max(minY, min(maxY, normalizedPoint.y))

        // 활성 영역 기준 정규화 (0~1)
        let normalizedX = (clampedXInActive - minX) / width
        let normalizedY = (clampedYInActive - minY) / height

        // 2) 가장자리 민감도 완화를 위한 이징 적용 (ease-in-out cosine)
        let ease: (CGFloat) -> CGFloat = { t in
            return 0.5 - 0.5 * cos(.pi * max(0, min(1, t)))
        }
        // 선형과 이징을 가중 혼합하여 중앙은 자연스럽게, 가장자리는 덜 민감하게
        let mixedX = normalizedX * (1 - edgeEasingStrength) + ease(normalizedX) * edgeEasingStrength
        let mixedY = normalizedY * (1 - edgeEasingStrength) + ease(normalizedY) * edgeEasingStrength

        // 3) 전체 민감도 조절: 대칭 감마 곡선 (중앙 민감도 완화)
        // gamma > 1 일 때 중앙 기울기(민감도)를 1/gamma 로 낮춰 과민 반응을 줄임
        let gammaMap: (CGFloat, CGFloat) -> CGFloat = { t, g in
            let tt = max(0, min(1, t))
            let e = g > 0 ? (1.0 / g) : 1.0
            if tt <= 0.5 {
                return 0.5 * pow(tt * 2, e)
            } else {
                return 1 - 0.5 * pow((1 - tt) * 2, e)
            }
        }
        let gammaX = gammaMap(mixedX, sensitivityGamma)
        let gammaY = gammaMap(mixedY, sensitivityGamma)

        // 4) 화면 좌표로 변환
        return CGPoint(
            x: gammaX * screenSize.width,
            y: gammaY * screenSize.height
        )
    }
    
    private func calculateFingerAngle(tip: VNRecognizedPoint, pip: VNRecognizedPoint) -> Double {
        let deltaX = tip.location.x - pip.location.x
        let deltaY = tip.location.y - pip.location.y
        return atan2(deltaY, deltaX)
    }
    
    private func addToHistory(position: CGPoint, distance: Double) {
        positionHistory.append(position)
        distanceHistory.append(distance)
        
        if positionHistory.count > historySize {
            positionHistory.removeFirst()
        }
        if distanceHistory.count > historySize {
            distanceHistory.removeFirst()
        }
    }
    
    private func calculateSmoothedPosition() -> CGPoint {
        guard !positionHistory.isEmpty else { return lastValidPosition }
        
        // 움직임 속도 계산으로 적응형 스무딩
        let currentPosition = positionHistory.last!
        var movementSpeed: CGFloat = 0
        
        if positionHistory.count >= 2 {
            let prevPosition = positionHistory[positionHistory.count - 2]
            movementSpeed = sqrt(pow(currentPosition.x - prevPosition.x, 2) + pow(currentPosition.y - prevPosition.y, 2))
        }
        
        // 빠른 움직임일 때는 스무딩을 덜 적용 (임계값을 낮춰 더 민감하게)
        if movementSpeed > 0.03 {
            // 빠른 움직임: 최신 값에 98% 가중치로 반응성 극대화
            let weights = [0.01, 0.01, 0.98]
            let count = min(positionHistory.count, weights.count)
            
            var weightedX: CGFloat = 0
            var weightedY: CGFloat = 0
            var totalWeight: CGFloat = 0
            
            for i in 0..<count {
                let index = positionHistory.count - 1 - i
                let weight = weights[i]
                let position = positionHistory[index]
                
                weightedX += position.x * weight
                weightedY += position.y * weight
                totalWeight += weight
            }
            
            let smoothedPosition = CGPoint(x: weightedX / totalWeight, y: weightedY / totalWeight)
            lastValidPosition = smoothedPosition
            return smoothedPosition
        } else {
            // 일반적인 움직임: 반응성 약간 강화
            let weights = [0.05, 0.10, 0.85]
            let count = min(positionHistory.count, weights.count)
            
            var weightedX: CGFloat = 0
            var weightedY: CGFloat = 0
            var totalWeight: CGFloat = 0
            
            for i in 0..<count {
                let index = positionHistory.count - 1 - i
                let weight = weights[i]
                let position = positionHistory[index]
                
                weightedX += position.x * weight
                weightedY += position.y * weight
                totalWeight += weight
            }
            
            let smoothedPosition = CGPoint(x: weightedX / totalWeight, y: weightedY / totalWeight)
            lastValidPosition = smoothedPosition
            return smoothedPosition
        }
    }
    
    private func calculateSmoothedDistance() -> Double {
        guard !distanceHistory.isEmpty else { return 0 }
        
        // 빠른 반응을 위해 최신 값에 더 큰 가중치
        let weights = [0.05, 0.15, 0.8]
        let count = min(distanceHistory.count, weights.count)
        
        var weightedDistance: Double = 0
        var totalWeight: Double = 0
        
        for i in 0..<count {
            let index = distanceHistory.count - 1 - i
            let weight = weights[i]
            
            weightedDistance += distanceHistory[index] * weight
            totalWeight += weight
        }
        
        return weightedDistance / totalWeight
    }
    
    private func calculateStability() -> Float {
        guard positionHistory.count >= 2 else { return 0 }
        
        var totalVariation: CGFloat = 0
        for i in 1..<positionHistory.count {
            let prev = positionHistory[i-1]
            let curr = positionHistory[i]
            let variation = sqrt(pow(curr.x - prev.x, 2) + pow(curr.y - prev.y, 2))
            totalVariation += variation
        }
        
        let avgVariation = totalVariation / CGFloat(positionHistory.count - 1)
        return Float(max(0, 1 - avgVariation * 10)) // 안정성을 0-1 범위로 정규화
    }
    
    private func adaptThresholds(based confidence: Float, stability: Float) {
        // 신뢰도와 안정성에 따라 임계값 조정
        let confidenceFactor = confidence
        let stabilityFactor = stability
        
        // 신뢰도가 높고 안정적일 때 더 민감하게, 그렇지 않으면 덜 민감하게
        adaptivePinchThreshold = 0.03 * Double(2 - confidenceFactor * stabilityFactor)
        adaptiveReleaseThreshold = 0.05 * Double(2 - confidenceFactor * stabilityFactor)
        
        // 범위 제한
        adaptivePinchThreshold = max(0.02, min(0.05, adaptivePinchThreshold))
        adaptiveReleaseThreshold = max(0.04, min(0.08, adaptiveReleaseThreshold))
    }
    
    private func detectPinchGesture(distance: Double, thumbAngle: Double, indexAngle: Double, confidence: Float) {
        // 각도 차이로 핀치 의도 확인
        let angleDifference = abs(thumbAngle - indexAngle)
        let isGestureIntentional = angleDifference > 0.5 && confidence > 0.6
        
        // 핀치 시작 감지
        if distance < adaptivePinchThreshold && isGestureIntentional && !isPinching {
            consecutivePinchFrames += 1
            consecutiveReleaseFrames = 0
            
            if consecutivePinchFrames >= stabilityThreshold {
                isPinching = true
                shouldClick = true
                isIndexFingerNearThumb = true
            }
        }
        // 핀치 해제 감지
        else if distance > adaptiveReleaseThreshold && isPinching {
            consecutiveReleaseFrames += 1
            consecutivePinchFrames = 0
            
            if consecutiveReleaseFrames >= stabilityThreshold {
                isPinching = false
                shouldClick = false
                isIndexFingerNearThumb = false
            }
        }
        // 중간 상태 유지
        else {
            isIndexFingerNearThumb = distance < adaptiveReleaseThreshold
        }
    }
}

// 조명 조건 열거형
enum LightingCondition {
    case bright
    case normal
    case dim
}

// MARK: - 고성능 최적화를 위한 헬퍼 클래스들

// 제스처 데이터 구조체
struct GestureData {
    let thumbPosition: CGPoint
    let indexPosition: CGPoint
    let distance: Double
    let confidence: Float
    let timestamp: CFTimeInterval
    let thumbAngle: Double
    let indexAngle: Double
}

// 고성능 원형 버퍼
class CircularBuffer<T> {
    private var buffer: [T?]
    private var head = 0
    private var tail = 0
    private var count = 0
    private let capacity: Int
    private let lock = NSLock()
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    func append(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer[tail] = element
        tail = (tail + 1) % capacity
        
        if count < capacity {
            count += 1
        } else {
            head = (head + 1) % capacity
        }
    }
    
    var last: T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard count > 0 else { return nil }
        let index = tail == 0 ? capacity - 1 : tail - 1
        return buffer[index]
    }
    
    var elements: [T] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [T] = []
        for i in 0..<count {
            let index = (head + i) % capacity
            if let element = buffer[index] {
                result.append(element)
            }
        }
        return result
    }
    
    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return count == 0
    }
}

// 칼만 필터 - 손 위치 예측 및 스무딩
class KalmanFilter {
    private var x: simd_double2 = simd_double2(0, 0) // 상태 벡터 (position)
    private var v: simd_double2 = simd_double2(0, 0) // 속도 벡터
    private var P: simd_double2x2 = matrix_identity_double2x2 // 공분산 행렬
    private let Q: simd_double2x2 // 프로세스 노이즈
    private let R: Double // 측정 노이즈
    private var lastTime: CFTimeInterval = 0
    
    init(processNoise: Double = 0.01, measurementNoise: Double = 0.1) {
        self.Q = simd_double2x2([simd_double2(processNoise, 0), 
                                simd_double2(0, processNoise)])
        self.R = measurementNoise
    }
    
    func update(measurement: CGPoint, timestamp: CFTimeInterval) -> CGPoint {
        let dt = lastTime > 0 ? timestamp - lastTime : 0.016 // 기본 60fps
        lastTime = timestamp
        
        // 예측 단계
        let F = simd_double2x2([simd_double2(1, 0), simd_double2(0, 1)])
        x = F * x + v * dt
        P = F * P * F.transpose + Q
        
        // 업데이트 단계
        let z = simd_double2(Double(measurement.x), Double(measurement.y))
        let H = matrix_identity_double2x2
        let S = H * P * H.transpose + simd_double2x2([simd_double2(R, 0), simd_double2(0, R)])
        let K = P * H.transpose * S.inverse
        
        x = x + K * (z - H * x)
        P = (matrix_identity_double2x2 - K * H) * P
        
        // 속도 업데이트
        if dt > 0 {
            v = (z - x) / dt
        }
        
        return CGPoint(x: x.x, y: x.y)
    }
    
    func predict(deltaTime: CFTimeInterval) -> CGPoint {
        let predicted = x + v * deltaTime
        return CGPoint(x: predicted.x, y: predicted.y)
    }
}

// 행렬 연산 확장
extension simd_double2x2 {
    var transpose: simd_double2x2 {
        return simd_double2x2([simd_double2(self[0][0], self[1][0]),
                              simd_double2(self[0][1], self[1][1])])
    }
    
    var inverse: simd_double2x2 {
        let det = self[0][0] * self[1][1] - self[0][1] * self[1][0]
        guard det != 0 else { return matrix_identity_double2x2 }
        
        let invDet = 1.0 / det
        return simd_double2x2([simd_double2(self[1][1] * invDet, -self[0][1] * invDet),
                              simd_double2(-self[1][0] * invDet, self[0][0] * invDet)])
    }
}

// MARK: - GestureRecognitionManager 고성능 확장
extension GestureRecognitionManager {
    
    // 적응형 동적 신뢰도 계산
    func adaptiveDynamicConfidence(baseConfidence: Float) -> Float {
        let recentGestures = gestureBuffer.elements.suffix(5)
        guard !recentGestures.isEmpty else { return baseConfidence }
        
        let avgConfidence = recentGestures.reduce(0) { $0 + $1.confidence } / Float(recentGestures.count)
        let confidenceVariance = recentGestures.reduce(0) { sum, gesture in
            sum + pow(gesture.confidence - avgConfidence, 2)
        } / Float(recentGestures.count)
        
        // 분산이 낮으면 (안정적이면) 임계값을 낮춰서 더 민감하게
        let adaptationFactor = max(0.7, 1.0 - confidenceVariance)
        return baseConfidence * adaptationFactor
    }
    
    // 손목과 손가락 간 거리로 손 크기 추정
    func calculateWristDistance(wrist: VNRecognizedPoint, thumb: VNRecognizedPoint, index: VNRecognizedPoint) -> Double {
        let wristToThumb = sqrt(pow(wrist.location.x - thumb.location.x, 2) + pow(wrist.location.y - thumb.location.y, 2))
        let wristToIndex = sqrt(pow(wrist.location.x - index.location.x, 2) + pow(wrist.location.y - index.location.y, 2))
        return (wristToThumb + wristToIndex) / 2
    }
    
    // 고급 필터링 - 다중 알고리즘 조합
    func advancedFiltering() -> (CGPoint, Double, Float) {
        let recentData = gestureBuffer.elements.suffix(historySize)
        guard recentData.count >= 2 else {
            return (gestureBuffer.last?.thumbPosition ?? .zero, gestureBuffer.last?.distance ?? 0, 0)
        }
        
        // 1. 가중 평균 (최근 데이터에 더 높은 가중치)
        var weightedPosition = CGPoint.zero
        var weightedDistance: Double = 0
        var totalWeight: Double = 0
        
        for (index, data) in recentData.enumerated() {
            let weight = Double(index + 1) * Double(data.confidence) // 시간 가중치 * 신뢰도 가중치
            weightedPosition.x += CGFloat(weight) * data.thumbPosition.x
            weightedPosition.y += CGFloat(weight) * data.thumbPosition.y
            weightedDistance += weight * data.distance
            totalWeight += weight
        }
        
        if totalWeight > 0 {
            weightedPosition.x /= CGFloat(totalWeight)
            weightedPosition.y /= CGFloat(totalWeight)
            weightedDistance /= totalWeight
        }
        
        // 2. 안정성 계산 - 위치 분산 + 신뢰도 분산
        let positions = recentData.map { $0.thumbPosition }
        let avgX = positions.reduce(0) { $0 + $1.x } / CGFloat(positions.count)
        let avgY = positions.reduce(0) { $0 + $1.y } / CGFloat(positions.count)
        
        let positionVariance = positions.reduce(0) { sum, pos in
            sum + pow(pos.x - avgX, 2) + pow(pos.y - avgY, 2)
        } / CGFloat(positions.count)
        
        let confidences = recentData.map { $0.confidence }
        let avgConfidence = confidences.reduce(0, +) / Float(confidences.count)
        let confidenceVariance = confidences.reduce(0) { sum, conf in
            sum + pow(conf - avgConfidence, 2)
        } / Float(confidences.count)
        
        let stability = max(0, 1.0 - Float(positionVariance) - confidenceVariance * 10)
        
        return (weightedPosition, weightedDistance, stability)
    }
    
    // 기계 학습 기반 적응형 임계값 조정
    func adaptiveThresholdLearning(confidence: Float, stability: Float, wristDistance: Double) {
        // 손 크기에 따른 임계값 조정
        let handSizeNormalization = min(max(wristDistance / 0.2, 0.7), 1.3) // 0.2는 평균 손목-손가락 거리
        
        // 신뢰도와 안정성 기반 조정
        let confidenceFactor = confidence > 0.8 ? 0.9 : (confidence > 0.6 ? 1.0 : 1.1)
        let stabilityFactor = stability > 0.7 ? 0.95 : (stability > 0.4 ? 1.0 : 1.05)
        
        // 적응형 학습률
        let learningRate = 0.01 * Double(confidence) * Double(stability)
        
        let targetPinchThreshold = 0.025 * handSizeNormalization * confidenceFactor * stabilityFactor
        let targetReleaseThreshold = 0.045 * handSizeNormalization * confidenceFactor * stabilityFactor
        
        // 지수 이동 평균으로 부드러운 조정
        adaptivePinchThreshold = adaptivePinchThreshold * (1 - learningRate) + targetPinchThreshold * learningRate
        adaptiveReleaseThreshold = adaptiveReleaseThreshold * (1 - learningRate) + targetReleaseThreshold * learningRate
        
        // 안전 범위 내에서 제한
        adaptivePinchThreshold = min(max(adaptivePinchThreshold, 0.015), 0.05)
        adaptiveReleaseThreshold = min(max(adaptiveReleaseThreshold, 0.03), 0.08)
    }
}

