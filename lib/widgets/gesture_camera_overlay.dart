import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/hand_landmarker_service.dart';

class GestureCameraOverlay extends StatefulWidget {
  final Function(Offset) onGestureClick;
  final Function(String, Offset) onGestureDrag; // Drag callback with action
  final Function(String, {int? scrollAmount}) onGestureSwipe;
  final Function(bool)? onVoiceRecording; // Voice recording callback
  final VoidCallback? onLeftEdgeHover; // Left edge hover callback

  const GestureCameraOverlay({
    super.key,
    required this.onGestureClick,
    required this.onGestureDrag,
    required this.onGestureSwipe,
    this.onVoiceRecording,
    this.onLeftEdgeHover,
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
  bool _isCameraAtTop = false; // Track if camera is at top of device

  // Left edge hover detection
  Timer? _leftEdgeHoverTimer;
  bool _isOnLeftEdge = false;
  static const double _leftEdgeWidth = 100.0; // Left edge detection zone width
  static const Duration _hoverDuration = Duration(seconds: 1); // 1 second hover

  // Cursor colors based on gesture (from Figma with exact values)
  Color _cursorColor = const Color(0x4D3D3D3D); // Default fill with alpha
  Color _cursorStrokeColor = const Color(0xFF949494); // Default stroke
  Color _cursorShadowColor = const Color(0x40000000); // Default shadow

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

          _gestureStatus =
              result.gesture + (_isCameraAtTop ? ' [상단]' : ' [하단]');

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

              // Check for left edge hover
              _checkLeftEdgeHover(_pointerPosition);

              // Transform thumbTip and indexTip positions as well
              if (result.thumbTipPosition != null &&
                  result.indexTipPosition != null) {
                double thumbX =
                    result.thumbTipPosition!.dx * displayWidth + offsetX;
                double thumbY = result.thumbTipPosition!.dy * displayHeight;
                if (!_isCameraAtTop) {
                  thumbY = (1.0 - result.thumbTipPosition!.dy) * displayHeight;
                }
                thumbY += offsetY;
                _thumbTipPosition = Offset(thumbX, thumbY);

                double indexX =
                    result.indexTipPosition!.dx * displayWidth + offsetX;
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
            // Cancel left edge hover when no pointer
            _checkLeftEdgeHover(null);
          }

          // Update cursor color based on pinch state (not gesture result)
          _updateCursorColor(result.gestureState);

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
          } else if (result.gesture.contains('드래그') &&
              _pointerPosition != null) {
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
            final match = RegExp(
              r'스크롤.*?\((-?\d+)\)',
            ).firstMatch(result.gesture);
            if (match != null) {
              final scrollAmount = int.parse(match.group(1)!);
              // 양수 = 아래로 이동 = 아래로 스크롤 (down scroll)
              // 음수 = 위로 이동 = 위로 스크롤 (up scroll)
              final direction = scrollAmount > 0 ? 'down' : 'up';
              debugPrint(
                '📜 SCROLL overlay: amount=$scrollAmount, dir=$direction',
              );
              widget.onGestureSwipe(
                direction,
                scrollAmount: scrollAmount.abs(),
              );
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
    _leftEdgeHoverTimer?.cancel();
    _cameraController?.dispose();
    _handService?.dispose();
    super.dispose();
  }

  void _checkLeftEdgeHover(Offset? position) {
    if (position == null) {
      // No pointer - cancel timer and reset
      if (_isOnLeftEdge) {
        _leftEdgeHoverTimer?.cancel();
        _isOnLeftEdge = false;
      }
      return;
    }

    final isOnLeftEdge = position.dx <= _leftEdgeWidth;

    if (isOnLeftEdge && !_isOnLeftEdge) {
      // Just entered left edge - start timer
      _isOnLeftEdge = true;
      _leftEdgeHoverTimer?.cancel();
      _leftEdgeHoverTimer = Timer(_hoverDuration, () {
        if (_isOnLeftEdge && mounted) {
          print('🎯 Left edge hover triggered!');
          widget.onLeftEdgeHover?.call();
        }
      });
    } else if (!isOnLeftEdge && _isOnLeftEdge) {
      // Left the left edge - cancel timer
      _isOnLeftEdge = false;
      _leftEdgeHoverTimer?.cancel();
    }
  }

  void _updateCursorColor(GestureState gestureState) {
    Color newFillColor;
    Color newStrokeColor;
    Color newShadowColor;

    // Change cursor color based on pinch state (exact Figma colors with alpha)
    switch (gestureState) {
      case GestureState.voiceRecording:
        // Ellipse 11 - Red (voice recording)
        // Fill: #FF0C004D, Stroke: #FF9494, Shadow: #FE5F5740
        newFillColor = const Color(0x4DFF0C00);
        newStrokeColor = const Color(0xFFFF9494);
        newShadowColor = const Color(0x40FE5F57);
        break;
      case GestureState.threePinch:
      case GestureState.scrolling:
        // Ellipse 10 - Green (3-finger pinch/scroll)
        // Fill: #00A91B4D, Stroke: #77DB87, Shadow: #27C84140
        newFillColor = const Color(0x4D00A91B);
        newStrokeColor = const Color(0xFF77DB87);
        newShadowColor = const Color(0x4027C841);
        break;
      case GestureState.twoPinch:
      case GestureState.dragging:
        // Ellipse 16 - Blue (2-finger pinch/drag)
        // Fill: #0070FF4D, Stroke: #80B6FA, Shadow: #4E9CFF40
        newFillColor = const Color(0x4D0070FF);
        newStrokeColor = const Color(0xFF80B6FA);
        newShadowColor = const Color(0x404E9CFF);
        break;
      case GestureState.idle:
        // Ellipse 12 - Dark gray (idle)
        // Fill: #3D3D3D4D, Stroke: #949494, Shadow: #00000040
        newFillColor = const Color(0x4D3D3D3D);
        newStrokeColor = const Color(0xFF949494);
        newShadowColor = const Color(0x40000000);
        break;
    }

    if (_cursorColor != newFillColor ||
        _cursorStrokeColor != newStrokeColor ||
        _cursorShadowColor != newShadowColor) {
      setState(() {
        _cursorColor = newFillColor;
        _cursorStrokeColor = newStrokeColor;
        _cursorShadowColor = newShadowColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent overlay to allow pointer events to pass through
        Positioned.fill(
          child: IgnorePointer(child: Container(color: Colors.transparent)),
        ),

        // Gesture status
        Positioned(
          top: 144,
          right: 16,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
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
        ),

        // Hand landmarks overlay - DISABLED (only show cursor)
        // if (_handLandmarks.isNotEmpty && _cameraController != null)
        //   IgnorePointer(
        //     child: CustomPaint(
        //       size: screenSize,
        //       painter: HandLandmarksPainter(
        //         landmarks: _handLandmarks,
        //         isCameraAtTop: _isCameraAtTop,
        //         cameraAspectRatio: _cameraController!.value.aspectRatio,
        //         screenSize: screenSize,
        //       ),
        //     ),
        //   ),

        // Pointer indicator (changes color based on gesture - Figma design)
        if (_pointerPosition != null)
          Positioned(
            left: _pointerPosition!.dx - 8,
            top: _pointerPosition!.dy - 8,
            child: IgnorePointer(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cursorColor, // Fill color with alpha
                  border: Border.all(
                    color: _cursorStrokeColor, // Stroke color (1px)
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cursorShadowColor, // Shadow color with alpha
                      blurRadius: 15.0, // Blur 15px
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
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
      final x2 =
          start.dx + unitX * (currentDistance + dashWidth).clamp(0, length);
      final y2 =
          start.dy + unitY * (currentDistance + dashWidth).clamp(0, length);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DottedLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
