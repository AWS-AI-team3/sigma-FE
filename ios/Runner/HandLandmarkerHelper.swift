import Foundation
import MediaPipeTasksVision
import AVFoundation

class HandLandmarkerHelper: NSObject {
    var handLandmarker: HandLandmarker?

    override init() {
        super.init()
        setupHandLandmarker()
    }

    private func setupHandLandmarker() {
        let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task")

        guard let modelPath = modelPath else {
            print("Failed to load model file")
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
        } catch {
            print("Failed to initialize HandLandmarker: \(error)")
        }
    }

    func detectHands(in pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation, timestamp: Int) {
        let mpImage = try? MPImage(pixelBuffer: pixelBuffer)
        guard let mpImage = mpImage else { return }

        do {
            try handLandmarker?.detectAsync(image: mpImage, timestampInMilliseconds: timestamp)
        } catch {
            print("Failed to detect hands: \(error)")
        }
    }
}

extension HandLandmarkerHelper: HandLandmarkerLiveStreamDelegate {
    func handLandmarker(_ handLandmarker: HandLandmarker, didFinishDetection result: HandLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        if let error = error {
            print("Hand detection error: \(error)")
            return
        }

        guard let result = result, let landmarks = result.landmarks.first else {
            NotificationCenter.default.post(name: .handLandmarksDetected, object: nil)
            return
        }

        // Convert landmarks to dictionary
        var landmarksArray: [[String: Double]] = []
        for landmark in landmarks {
            landmarksArray.append([
                "x": Double(landmark.x),
                "y": Double(landmark.y),
                "z": Double(landmark.z)
            ])
        }

        NotificationCenter.default.post(
            name: .handLandmarksDetected,
            object: nil,
            userInfo: ["landmarks": landmarksArray]
        )
    }
}

extension Notification.Name {
    static let handLandmarksDetected = Notification.Name("handLandmarksDetected")
}
