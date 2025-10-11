import Flutter
import AVFoundation
import MediaPipeTasksVision

class HandLandmarkerPlugin: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var handLandmarker: HandLandmarker?
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
    private var lastFrameTime: Int = 0

    init(messenger: FlutterBinaryMessenger) {
        super.init()

        // Setup method channel
        let methodChannel = FlutterMethodChannel(
            name: "gesture_browser/hand_landmarker",
            binaryMessenger: messenger
        )
        methodChannel.setMethodCallHandler(handleMethodCall)

        // Setup event channel
        let eventChannel = FlutterEventChannel(
            name: "gesture_browser/hand_landmarks",
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(self)
    }

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializeHandLandmarker(result: result)
        case "startDetection":
            startDetection(result: result)
        case "stopDetection":
            stopDetection(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initializeHandLandmarker(result: @escaping FlutterResult) {
        guard let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") else {
            result(FlutterError(code: "MODEL_NOT_FOUND", message: "hand_landmarker.task not found", details: nil))
            return
        }

        let options = HandLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numHands = 1
        options.minHandDetectionConfidence = 0.5
        options.minHandPresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.handLandmarkerLiveStreamDelegate = self

        do {
            handLandmarker = try HandLandmarker(options: options)
            result(nil)
        } catch {
            result(FlutterError(code: "INIT_ERROR", message: "Failed to initialize: \(error)", details: nil))
        }
    }

    private func startDetection(result: @escaping FlutterResult) {
        setupCamera()
        captureSession?.startRunning()
        result(nil)
    }

    private func stopDetection(result: @escaping FlutterResult) {
        captureSession?.stopRunning()
        result(nil)
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium

        guard let captureSession = captureSession,
              let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }

        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }

        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

        if let videoDataOutput = videoDataOutput, captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension HandLandmarkerPlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let currentTimeMs = Int(Date().timeIntervalSince1970 * 1000)
        if currentTimeMs - lastFrameTime < 100 { // Process max 10 fps
            return
        }
        lastFrameTime = currentTimeMs

        let mpImage = try? MPImage(pixelBuffer: pixelBuffer)
        guard let mpImage = mpImage else { return }

        try? handLandmarker?.detectAsync(image: mpImage, timestampInMilliseconds: currentTimeMs)
    }
}

// MARK: - HandLandmarkerLiveStreamDelegate

extension HandLandmarkerPlugin: HandLandmarkerLiveStreamDelegate {
    func handLandmarker(_ handLandmarker: HandLandmarker, didFinishDetection result: HandLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        guard let eventSink = eventSink else { return }

        if let error = error {
            print("Hand detection error: \(error)")
            DispatchQueue.main.async {
                eventSink(nil)
            }
            return
        }

        guard let result = result, let landmarks = result.landmarks.first else {
            DispatchQueue.main.async {
                eventSink(nil)
            }
            return
        }

        // Convert landmarks to array of dictionaries
        var landmarksArray: [[String: Any]] = []
        for landmark in landmarks {
            landmarksArray.append([
                "x": Double(landmark.x),
                "y": Double(landmark.y),
                "z": Double(landmark.z)
            ])
        }

        // Get device orientation
        // Use interface orientation from main thread instead
        var isCameraAtTop = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            // portraitUpsideDown means home button at top (camera at top for front camera)
            isCameraAtTop = (interfaceOrientation == .portraitUpsideDown)
            print("🔄 Interface orientation: \(interfaceOrientation.rawValue), camera at top: \(isCameraAtTop)")
        }

        let resultData: [String: Any] = [
            "landmarks": landmarksArray,
            "isCameraAtTop": isCameraAtTop
        ]

        DispatchQueue.main.async {
            eventSink(resultData)
        }
    }
}
