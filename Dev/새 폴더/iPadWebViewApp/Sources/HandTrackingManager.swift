import Foundation
import AVFoundation
import Vision
import Combine

class HandTrackingManager: NSObject, ObservableObject {
    @Published var thumbPosition: CGPoint = .zero
    @Published var isPinching: Bool = false
    @Published var isTracking: Bool = false

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoDataQueue = DispatchQueue(label: "VideoDataQueue")

    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    private var previousThumbTip: CGPoint?
    private var previousIndexTip: CGPoint?

    // 핀치 감지를 위한 임계값 (픽셀 단위)
    private let pinchThreshold: CGFloat = 50.0

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        guard let captureSession = captureSession else { return }

        // 전면 카메라 설정
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .front) else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: videoDataQueue)

            if let videoOutput = videoOutput,
               captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            // Vision 요청 설정
            handPoseRequest.maximumHandCount = 1

        } catch {
            print("카메라 설정 실패: \(error)")
        }
    }

    func startTracking() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isTracking = true
            }
        }
    }

    func stopTracking() {
        captureSession?.stopRunning()
        isTracking = false
    }

    private func processHandPose(_ observation: VNHumanHandPoseObservation, imageSize: CGSize) {
        guard let thumbTipPoint = try? observation.recognizedPoint(.thumbTip),
              let indexTipPoint = try? observation.recognizedPoint(.indexTip),
              thumbTipPoint.confidence > 0.3,
              indexTipPoint.confidence > 0.3 else { return }

        // 좌표를 화면 좌표계로 변환
        let thumbTip = CGPoint(
            x: thumbTipPoint.location.x * imageSize.width,
            y: (1 - thumbTipPoint.location.y) * imageSize.height
        )

        let indexTip = CGPoint(
            x: indexTipPoint.location.x * imageSize.width,
            y: (1 - indexTipPoint.location.y) * imageSize.height
        )

        // 엄지 위치를 커서 위치로 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.thumbPosition = thumbTip
        }

        // 핀치 제스처 감지 (엄지와 검지 거리)
        let distance = hypot(thumbTip.x - indexTip.x, thumbTip.y - indexTip.y)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let wasPinching = self.isPinching
            self.isPinching = distance < self.pinchThreshold

            // 핀치 상태 변화 감지 (클릭 이벤트 발생)
            if !wasPinching && self.isPinching {
                NotificationCenter.default.post(name: .handGestureClick, object: self.thumbPosition)
            }
        }

        previousThumbTip = thumbTip
        previousIndexTip = indexTip
    }
}

extension HandTrackingManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let imageSize = CGSize(width: imageWidth, height: imageHeight)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([handPoseRequest])

            guard let observations = handPoseRequest.results,
                  let firstHand = observations.first else { return }

            processHandPose(firstHand, imageSize: imageSize)

        } catch {
            print("손 추적 실패: \(error)")
        }
    }
}

extension Notification.Name {
    static let handGestureClick = Notification.Name("handGestureClick")
}
