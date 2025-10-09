//
//  GestureRecognitionManager.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import Vision
import AVFoundation

@MainActor
class GestureRecognitionManager: ObservableObject {
    @Published var thumbPosition: CGPoint = .zero
    @Published var isIndexFingerNearThumb: Bool = false
    @Published var isPinching: Bool = false
    @Published var shouldClick: Bool = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "gesture.recognition.queue")
    
    private var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    
    func startGestureRecognition() {
        sessionQueue.async {
            self.setupCaptureSession()
        }
    }
    
    func stopGestureRecognition() {
        captureSession?.stopRunning()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        captureSession.sessionPreset = .medium
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("카메라를 찾을 수 없습니다.")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: sessionQueue)
            
            if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.startRunning()
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
}

extension GestureRecognitionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up)
        
        do {
            try imageRequestHandler.perform([handPoseRequest])
            
            if let observation = handPoseRequest.results?.first {
                processHandPose(observation)
            }
        } catch {
            print("손 인식 처리 오류: \(error)")
        }
    }
    
    private func processHandPose(_ observation: VNHumanHandPoseObservation) {
        guard let thumbTip = try? observation.recognizedPoint(.thumbTip),
              let indexTip = try? observation.recognizedPoint(.indexTip),
              thumbTip.confidence > 0.3,
              indexTip.confidence > 0.3 else { return }
        
        let thumbPoint = CGPoint(x: thumbTip.location.x, y: 1 - thumbTip.location.y)
        let indexPoint = CGPoint(x: indexTip.location.x, y: 1 - indexTip.location.y)
        
        let distance = sqrt(pow(thumbPoint.x - indexPoint.x, 2) + pow(thumbPoint.y - indexPoint.y, 2))
        
        DispatchQueue.main.async {
            // 엄지 끝을 커서 위치로 사용
            self.thumbPosition = thumbPoint
            
            // 검지와 엄지가 가까우면 클릭 상태로 인식
            self.isIndexFingerNearThumb = distance < 0.05
            
            // 핀치 제스처 감지
            if distance < 0.03 && !self.isPinching {
                self.isPinching = true
                self.shouldClick = true
            } else if distance > 0.05 && self.isPinching {
                self.isPinching = false
                self.shouldClick = false
            }
        }
    }
}