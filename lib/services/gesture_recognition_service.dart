import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class GestureRecognitionService {
  late PoseDetector _poseDetector;
  bool _isProcessing = false;

  Offset? _lastPointerPosition;
  DateTime? _lastClickTime;
  PoseLandmark? _lastRightHandPosition;

  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<Map<String, dynamic>> processFrame(CameraImage image) async {
    if (_isProcessing) return {'gesture': '처리 중'};

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return {'gesture': '이미지 변환 실패'};
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        _isProcessing = false;
        return {'gesture': '손 감지 안됨'};
      }

      final result = _analyzeGesture(poses.first, image.width, image.height);
      _isProcessing = false;
      return result;
    } catch (e) {
      _isProcessing = false;
      return {'gesture': '오류: $e'};
    }
  }

  Map<String, dynamic> _analyzeGesture(Pose pose, int width, int height) {
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];
    final rightPinky = pose.landmarks[PoseLandmarkType.rightPinky];

    if (rightWrist == null) {
      return {'gesture': '손목 감지 안됨'};
    }

    // Map pose coordinates to screen coordinates
    final screenX = rightWrist.x;
    final screenY = rightWrist.y;
    final pointerPosition = Offset(screenX, screenY);

    // Detect gestures
    Map<String, dynamic> result = {
      'gesture': '추적 중',
      'position': pointerPosition,
    };

    // Click detection (pinch gesture - when index and thumb are close)
    if (rightIndex != null) {
      final distance = _calculateDistance(rightWrist, rightIndex);

      if (distance < 30) {
        // Threshold for "pinch"
        final now = DateTime.now();
        if (_lastClickTime == null ||
            now.difference(_lastClickTime!).inMilliseconds > 500) {
          result['gesture'] = '클릭!';
          result['action'] = 'click';
          _lastClickTime = now;
        }
      }
    }

    // Swipe detection
    if (_lastRightHandPosition != null) {
      final dx = rightWrist.x - _lastRightHandPosition!.x;
      final dy = rightWrist.y - _lastRightHandPosition!.y;
      final distance = dx.abs() + dy.abs();

      if (distance > 100) {
        // Threshold for swipe
        if (dx.abs() > dy.abs()) {
          // Horizontal swipe
          result['gesture'] = dx > 0 ? '오른쪽 스와이프' : '왼쪽 스와이프';
          result['action'] = 'swipe';
          result['direction'] = dx > 0 ? 'right' : 'left';
        } else {
          // Vertical swipe
          result['gesture'] = dy > 0 ? '아래 스와이프' : '위 스와이프';
          result['action'] = 'swipe';
          result['direction'] = dy > 0 ? 'down' : 'up';
        }
      }
    }

    _lastRightHandPosition = rightWrist;
    _lastPointerPosition = pointerPosition;

    return result;
  }

  double _calculateDistance(PoseLandmark point1, PoseLandmark point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return (dx * dx + dy * dy).abs();
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _poseDetector.close();
  }
}
