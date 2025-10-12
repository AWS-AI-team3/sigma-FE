import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/hand_landmarker_service.dart';

class GestureCameraOverlay extends StatefulWidget {
  final Function(Offset) onGestureClick;
  final Function(String, Offset) onGestureDrag;  // Drag callback with action
  final Function(String, {int? scrollAmount}) onGestureSwipe;
  final Function(bool)? onVoiceRecording;  // Voice recording callback

  const GestureCameraOverlay({
    super.key,
    required this.onGestureClick,
    required this.onGestureDrag,
    required this.onGestureSwipe,
    this.onVoiceRecording,
  });

  @override
  State<GestureCameraOverlay> createState() => _GestureCameraOverlayState();
}

class _GestureCameraOverlayState extends State<GestureCameraOverlay> {
  CameraController? _cameraController;
  HandLandmarkerService? _handService;
  bool _isInitialized = false;
  String _gestureStatus = '초기화 중...';
  List<HandLandmark> _handLandmarks = [];
  Offset? _pointerPosition;
  Offset? _thumbTipPosition;
  Offset? _indexTipPosition;
  bool _isCameraAtTop = false;  // Track if camera is at top of device
  bool _showCameraPreview = true;  // Camera preview toggle

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateOrientation();
  }

  void _updateOrientation() {
    // We need to detect actual device orientation
    // For now, we'll add a toggle or use accelerometer
    // Simplified: assume camera at bottom for now
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOrientation();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _gestureStatus = '카메라를 찾을 수 없음';
        });
        return;
      }

      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _handService = HandLandmarkerService();
      _handService!.setResultCallback((result) {
        if (!mounted) return;

        setState(() {
          _handLandmarks = result.landmarks;
          _isCameraAtTop = result.isCameraAtTop;

          _gestureStatus = result.gesture + (_isCameraAtTop ? ' [상단]' : ' [하단]');

          if (result.pointerPosition != null) {
            final screenSize = MediaQuery.of(context).size;

            // MediaPipe coordinates are in camera resolution space
            // We need to convert them to screen space accounting for aspect ratio
            if (_cameraController != null) {
              final cameraAspect = _cameraController!.value.aspectRatio;
              final screenAspect = screenSize.width / screenSize.height;

              // Calculate the actual display size of camera feed on screen
              double displayWidth, displayHeight;
              if (cameraAspect > screenAspect) {
                // Camera is wider - fit to width
                displayWidth = screenSize.width;
                displayHeight = screenSize.width / cameraAspect;
              } else {
                // Camera is taller - fit to height
                displayHeight = screenSize.height;
                displayWidth = screenSize.height * cameraAspect;
              }

              // Calculate offsets to center the camera feed
              final offsetX = (screenSize.width - displayWidth) / 2;
              final offsetY = (screenSize.height - displayHeight) / 2;

              // Transform coordinates
              double x = result.pointerPosition!.dx * displayWidth + offsetX;
              double y = result.pointerPosition!.dy * displayHeight;

              if (!_isCameraAtTop) {
                y = (1.0 - result.pointerPosition!.dy) * displayHeight;
              }
              y += offsetY;

              _pointerPosition = Offset(x, y);

              // Transform thumbTip and indexTip positions as well
              if (result.thumbTipPosition != null && result.indexTipPosition != null) {
                double thumbX = result.thumbTipPosition!.dx * displayWidth + offsetX;
                double thumbY = result.thumbTipPosition!.dy * displayHeight;
                if (!_isCameraAtTop) {
                  thumbY = (1.0 - result.thumbTipPosition!.dy) * displayHeight;
                }
                thumbY += offsetY;
                _thumbTipPosition = Offset(thumbX, thumbY);

                double indexX = result.indexTipPosition!.dx * displayWidth + offsetX;
                double indexY = result.indexTipPosition!.dy * displayHeight;
                if (!_isCameraAtTop) {
                  indexY = (1.0 - result.indexTipPosition!.dy) * displayHeight;
                }
                indexY += offsetY;
                _indexTipPosition = Offset(indexX, indexY);
              }
            } else {
              _pointerPosition = null;
              _thumbTipPosition = null;
              _indexTipPosition = null;
            }
          } else {
            _pointerPosition = null;
            _thumbTipPosition = null;
            _indexTipPosition = null;
          }

          // Handle gestures
          if (result.gesture == '🎤 녹음 중') {
            // Voice recording started
            widget.onVoiceRecording?.call(true);
          } else if (result.gesture == '🛑 녹음 중지') {
            // Voice recording stopped
            widget.onVoiceRecording?.call(false);
          } else if (result.gesture == '클릭!' && _pointerPosition != null) {
            // 정확히 '클릭!' 제스처일 때만 (한 번만 발생)
            widget.onGestureClick(_pointerPosition!);
          } else if (result.gesture == '드래그!' && _pointerPosition != null) {
            // 드래그 시작 - mousedown
            widget.onGestureDrag('start', _pointerPosition!);
          } else if (result.gesture.contains('드래그') && _pointerPosition != null) {
            // 드래그 중 - mousemove
            widget.onGestureDrag('move', _pointerPosition!);
          } else if (result.gesture == '드래그 완료') {
            // 드래그 종료 - mouseup
            if (_pointerPosition != null) {
              widget.onGestureDrag('end', _pointerPosition!);
            }
          } else if (result.gesture.contains('스와이프')) {
            if (result.gesture.contains('왼쪽')) {
              widget.onGestureSwipe('left');
            } else if (result.gesture.contains('오른쪽')) {
              widget.onGestureSwipe('right');
            }
          } else if (result.gesture.contains('스크롤')) {
            // 스크롤 속도 추출 (예: "스크롤! (50)" -> 50)
            final match = RegExp(r'스크롤.*?\((-?\d+)\)').firstMatch(result.gesture);
            if (match != null) {
              final scrollAmount = int.parse(match.group(1)!);
              // 양수 = 아래로 이동 = 아래로 스크롤 (down scroll)
              // 음수 = 위로 이동 = 위로 스크롤 (up scroll)
              final direction = scrollAmount > 0 ? 'down' : 'up';
              debugPrint('📜 SCROLL overlay: amount=$scrollAmount, dir=$direction');
              widget.onGestureSwipe(direction, scrollAmount: scrollAmount.abs());
            }
          }
        });
      });

      await _handService!.initialize();
      await _handService!.startDetection();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _gestureStatus = '준비됨';
        });
      }
    } catch (e) {
      setState(() {
        _gestureStatus = '오류: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _handService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Camera preview (small, top-right corner)
        if (_showCameraPreview)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 160,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black87,
                            child: const Icon(
                              Icons.videocam,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                          Center(
                            child: Text(
                              '제스처 추적 중',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),
          ),

        // Camera toggle button
        Positioned(
          top: 16,
          right: _showCameraPreview ? 184 : 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showCameraPreview = !_showCameraPreview;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showCameraPreview ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _showCameraPreview ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        // Gesture status
        Positioned(
          top: 144,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _gestureStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Hand landmarks overlay
        if (_handLandmarks.isNotEmpty && _cameraController != null)
          CustomPaint(
            size: screenSize,
            painter: HandLandmarksPainter(
              landmarks: _handLandmarks,
              isCameraAtTop: _isCameraAtTop,
              cameraAspectRatio: _cameraController!.value.aspectRatio,
              screenSize: screenSize,
            ),
          ),

        // Pointer indicator
        if (_pointerPosition != null)
          Positioned(
            left: _pointerPosition!.dx - 7.5,
            top: _pointerPosition!.dy - 7.5,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }
}

class HandLandmarksPainter extends CustomPainter {
  final List<HandLandmark> landmarks;
  final bool isCameraAtTop;
  final double cameraAspectRatio;
  final Size screenSize;

  HandLandmarksPainter({
    required this.landmarks,
    this.isCameraAtTop = false,
    required this.cameraAspectRatio,
    required this.screenSize,
  });

  // Hand connections (bone structure)
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8], // Index
    [0, 9], [9, 10], [10, 11], [11, 12], // Middle
    [0, 13], [13, 14], [14, 15], [15, 16], // Ring
    [0, 17], [17, 18], [18, 19], [19, 20], // Pinky
    [5, 9], [9, 13], [13, 17], // Palm
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || landmarks.length < 21) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8
      ..style = PaintingStyle.fill;

    // Calculate display size and offset (same as pointer calculation)
    final screenAspect = screenSize.width / screenSize.height;
    double displayWidth, displayHeight;
    if (cameraAspectRatio > screenAspect) {
      displayWidth = screenSize.width;
      displayHeight = screenSize.width / cameraAspectRatio;
    } else {
      displayHeight = screenSize.height;
      displayWidth = screenSize.height * cameraAspectRatio;
    }

    final offsetX = (screenSize.width - displayWidth) / 2;
    final offsetY = (screenSize.height - displayHeight) / 2;

    // Draw connections
    for (final connection in connections) {
      final start = landmarks[connection[0]];
      final end = landmarks[connection[1]];

      // Transform coordinates (same as pointer)
      double startX = start.x * displayWidth + offsetX;
      double startY = start.y * displayHeight;
      double endX = end.x * displayWidth + offsetX;
      double endY = end.y * displayHeight;

      // Flip Y when camera is at BOTTOM
      if (!isCameraAtTop) {
        startY = (1.0 - start.y) * displayHeight;
        endY = (1.0 - end.y) * displayHeight;
      }
      startY += offsetY;
      endY += offsetY;

      final startPoint = Offset(startX, startY);
      final endPoint = Offset(endX, endY);

      canvas.drawLine(startPoint, endPoint, paint);
    }

    // Draw landmarks
    for (final landmark in landmarks) {
      double x = landmark.x * displayWidth + offsetX;
      double y = landmark.y * displayHeight;

      // Flip Y when camera is at BOTTOM
      if (!isCameraAtTop) {
        y = (1.0 - landmark.y) * displayHeight;
      }
      y += offsetY;

      final point = Offset(x, y);
      canvas.drawCircle(point, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(HandLandmarksPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}

class DottedLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  DottedLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distanceSquared = dx * dx + dy * dy;
    if (distanceSquared == 0) return;

    final length = dart_math.sqrt(distanceSquared);
    final unitX = dx / length;
    final unitY = dy / length;

    double currentDistance = 0;
    while (currentDistance < length) {
      final x1 = start.dx + unitX * currentDistance;
      final y1 = start.dy + unitY * currentDistance;
      final x2 = start.dx + unitX * (currentDistance + dashWidth).clamp(0, length);
      final y2 = start.dy + unitY * (currentDistance + dashWidth).clamp(0, length);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DottedLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
