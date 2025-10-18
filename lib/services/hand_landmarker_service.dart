import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class HandLandmark {
  final double x;
  final double y;
  final double z;

  HandLandmark(this.x, this.y, this.z);
}

class HandDetectionResult {
  final List<HandLandmark> landmarks;
  final String gesture;
  final Offset? pointerPosition;
  final bool isCameraAtTop;
  final Offset? thumbTipPosition;
  final Offset? indexTipPosition;
  final GestureState gestureState; // Current pinch state

  HandDetectionResult({
    required this.landmarks,
    this.gesture = '감지 중',
    this.pointerPosition,
    this.isCameraAtTop = false,
    this.thumbTipPosition,
    this.indexTipPosition,
    this.gestureState = GestureState.idle,
  });
}

enum GestureState {
  idle,
  twoPinch, // 2핑거 핀치 (엄지+검지): 클릭 대기
  dragging, // 드래그 중
  threePinch, // 3핑거 핀치 (엄지+검지+중지): 스크롤/스와이프 대기
  scrolling, // 스크롤 중
  voiceRecording, // 음성 녹음 중 (엄지+약지 핀치)
}

class HandLandmarkerService {
  static const MethodChannel _channel = MethodChannel(
    'gesture_browser/hand_landmarker',
  );
  static const EventChannel _eventChannel = EventChannel(
    'gesture_browser/hand_landmarks',
  );

  List<HandLandmark>? _lastLandmarks;
  DateTime? _lastGestureTime;
  Offset? _swipeStartPosition;
  StreamSubscription? _subscription;
  Function(HandDetectionResult)? _onResultCallback;

  // Gesture state tracking
  GestureState _currentState = GestureState.idle;
  Offset? _gestureStartPosition;

  // Cursor smoothing (손떨림 보정)
  Offset? _lastSmoothedPosition;
  static const double SMOOTHING_FACTOR = 0.3; // 0~1, 낮을수록 부드러움

  // Cursor stabilization (커서 고정)
  Offset? _stabilizedCursorPosition; // 고정된 커서 위치
  Offset? _lastWristPosition; // 이전 손목 위치 (움직임 감지용)
  static const double MOVEMENT_THRESHOLD = 0.006; // 고정 조건: 더 작은 움직임만 고정 (0.015 → 0.008)
  static const double BREAK_LOCK_THRESHOLD = 0.025; // 고정 해제: 더 민감하게 (0.04 → 0.025)
  static const int STABILITY_FRAMES = 5; // 고정까지 더 오래 걸림 (3 → 5)
  int _stabilityCounter = 0; // 안정 카운터

  // Pinch detection thresholds
  static const double PINCH_THRESHOLD = 0.02; // 2핑거 핀치 감지 거리
  static const double SCROLL_PINCH_THRESHOLD = 0.04; // 3핑거 스크롤 감지 거리 (더 여유있게)
  static const double VOICE_PINCH_THRESHOLD = 0.04; // 음성 핀치 (엄지+약지) 감지 거리
  static const double DRAG_THRESHOLD = 0.05; // 드래그 시작 거리
  static const double DEADZONE_RADIUS = 0.11; // 떨림 방지 영역

  // Scroll/Swipe thresholds
  static const double SWIPE_THRESHOLD =
      0.15; // X축 스와이프 감지 거리 (0.08 -> 0.15, 더 크게 움직여야)
  static const double SCROLL_SPEED_MULTIPLIER =
      100.0; // Y축 이동 거리 → 스크롤 픽셀 (0.1 이동 = 30px)
  static const int SWIPE_COOLDOWN_MS = 800; // 쿨다운 증가 (500 -> 800)

  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');

      _subscription = _eventChannel.receiveBroadcastStream().listen((data) {
        if (data == null) {
          _onResultCallback?.call(HandDetectionResult(landmarks: []));
          return;
        }

        final dataMap = data as Map;
        final landmarksData = dataMap['landmarks'] as List;
        final isCameraAtTop = dataMap['isCameraAtTop'] as bool? ?? false;

        List<HandLandmark> landmarks = landmarksData.map((lm) {
          final map = lm as Map;
          return HandLandmark(
            (map['x'] as num).toDouble(),
            (map['y'] as num).toDouble(),
            (map['z'] as num).toDouble(),
          );
        }).toList();

        final result = _analyzeGesture(landmarks, isCameraAtTop);
        _onResultCallback?.call(result);
      });

      debugPrint('HandLandmarker initialized successfully');
    } catch (e) {
      debugPrint('Error initializing HandLandmarker: $e');
      rethrow;
    }
  }

  void setResultCallback(Function(HandDetectionResult) callback) {
    _onResultCallback = callback;
  }

  Future<void> startDetection() async {
    try {
      await _channel.invokeMethod('startDetection');
    } catch (e) {
      debugPrint('Error starting detection: $e');
    }
  }

  Future<void> stopDetection() async {
    try {
      await _channel.invokeMethod('stopDetection');
    } catch (e) {
      debugPrint('Error stopping detection: $e');
    }
  }

  HandDetectionResult _analyzeGesture(
    List<HandLandmark> landmarks,
    bool isCameraAtTop,
  ) {
    if (landmarks.isEmpty || landmarks.length < 21) {
      _resetGestureState();
      return HandDetectionResult(
        landmarks: landmarks,
        isCameraAtTop: isCameraAtTop,
        gestureState: GestureState.idle,
      );
    }

    final indexTip = landmarks[8];
    final indexMCP = landmarks[5];
    final thumbTip = landmarks[4];
    final middleTip = landmarks[12];
    final ringTip = landmarks[16]; // 약지 끝
    final wrist = landmarks[0];

    // 커서: 엄지와 검지 사이 중점
    final rawPointerPosition = Offset(
      (thumbTip.x + indexTip.x) / 2,
      (thumbTip.y + indexTip.y) / 2,
    );

    // 손목 위치
    final wristPosition = Offset(wrist.x, wrist.y);

    // 움직임 감지 및 커서 안정화 (손목 기준)
    Offset pointerPosition;

    if (_lastWristPosition != null) {
      // 손목의 이동 거리 계산
      final dx = wristPosition.dx - _lastWristPosition!.dx;
      final dy = wristPosition.dy - _lastWristPosition!.dy;
      final movement = dart_math.sqrt(dx * dx + dy * dy);

      // 커서가 고정된 상태에서 큰 움직임 감지 → 즉시 해제
      if (_stabilizedCursorPosition != null && movement > BREAK_LOCK_THRESHOLD) {
        debugPrint('🔓 CURSOR FORCE UNLOCKED (large movement: ${movement.toStringAsFixed(3)})');
        _stabilityCounter = 0;
        _stabilizedCursorPosition = null;
        
        // 즉시 새 위치로 이동
        pointerPosition = rawPointerPosition;
        _lastSmoothedPosition = rawPointerPosition;
      } else if (movement < MOVEMENT_THRESHOLD) {
        // 움직임이 작음 → 안정 카운터 증가
        _stabilityCounter++;

        if (_stabilityCounter >= STABILITY_FRAMES) {
          // 충분히 안정됨 → 커서 고정
          if (_stabilizedCursorPosition == null) {
            // 스무딩된 마지막 위치를 고정 위치로 설정
            _stabilizedCursorPosition = _lastSmoothedPosition ?? rawPointerPosition;
            debugPrint('🔒 CURSOR LOCKED at (${_stabilizedCursorPosition!.dx.toStringAsFixed(3)}, ${_stabilizedCursorPosition!.dy.toStringAsFixed(3)})');
          }
          // 고정된 위치 사용 (절대 변경 안 함)
          pointerPosition = _stabilizedCursorPosition!;
        } else {
          // 아직 안정화 중 → 스무딩 적용
          pointerPosition = _lastSmoothedPosition == null
              ? rawPointerPosition
              : Offset(
                  _lastSmoothedPosition!.dx +
                      (rawPointerPosition.dx - _lastSmoothedPosition!.dx) * SMOOTHING_FACTOR,
                  _lastSmoothedPosition!.dy +
                      (rawPointerPosition.dy - _lastSmoothedPosition!.dy) * SMOOTHING_FACTOR,
                );
        }
      } else {
        // 움직임이 중간 크기 → 커서 고정 해제
        if (_stabilizedCursorPosition != null) {
          debugPrint('🔓 CURSOR UNLOCKED (movement: ${movement.toStringAsFixed(3)})');
        }
        _stabilityCounter = 0;
        _stabilizedCursorPosition = null;

        // 스무딩 적용
        pointerPosition = _lastSmoothedPosition == null
            ? rawPointerPosition
            : Offset(
                _lastSmoothedPosition!.dx +
                    (rawPointerPosition.dx - _lastSmoothedPosition!.dx) * SMOOTHING_FACTOR,
                _lastSmoothedPosition!.dy +
                    (rawPointerPosition.dy - _lastSmoothedPosition!.dy) * SMOOTHING_FACTOR,
              );
      }
    } else {
      // 첫 프레임
      pointerPosition = rawPointerPosition;
      _stabilityCounter = 0;
      _stabilizedCursorPosition = null;
    }

    _lastWristPosition = wristPosition;
    _lastSmoothedPosition = pointerPosition;

    String gesture = '대기 중';

    final now = DateTime.now();
    final timeSinceLastGesture = _lastGestureTime != null
        ? now.difference(_lastGestureTime!).inMilliseconds
        : 999999;

    // 핀치 감지
    final thumbIndexDist = _calculateDistance(thumbTip, indexTip);
    final thumbMiddleDist = _calculateDistance(thumbTip, middleTip); // 엄지+중지
    final thumbRingDist = _calculateDistance(thumbTip, ringTip); // 엄지+약지

    // 각 핀치 타입 판별 (new_layout 방식)
    // 3핑거 스크롤: 엄지가 검지, 중지 둘 다와 가까움 (가장 먼저 체크)
    final isThreePinch =
        thumbIndexDist < SCROLL_PINCH_THRESHOLD &&
        thumbMiddleDist < SCROLL_PINCH_THRESHOLD;

    // 2핑거 클릭: 엄지+검지만 가까움 (3핑거가 아닐 때)
    final isTwoPinch = !isThreePinch && thumbIndexDist < PINCH_THRESHOLD;

    // 음성 핀치: 엄지+약지만 가깝고, 검지는 멀어야 함
    final isVoicePinch =
        thumbRingDist < VOICE_PINCH_THRESHOLD &&
        thumbIndexDist > PINCH_THRESHOLD * 1.5; // 검지는 충분히 멀리

    switch (_currentState) {
      case GestureState.idle:
        if (isVoicePinch && !isTwoPinch && !isThreePinch) {
          // 음성 녹음 시작 (엄지+약지만, 다른 손가락 안 붙음)
          _currentState = GestureState.voiceRecording;
          _gestureStartPosition = pointerPosition;
          gesture = '🎤 녹음 중';
          debugPrint('🎤 VOICE RECORDING START');
        } else if (isThreePinch) {
          // 3핑거 핀치 시작: 스크롤/스와이프 대기
          _currentState = GestureState.threePinch;
          _gestureStartPosition = pointerPosition;
          gesture = '3핑거 대기';
          debugPrint(
            '✋ 3-PINCH START at (${pointerPosition.dx.toStringAsFixed(2)}, ${pointerPosition.dy.toStringAsFixed(2)})',
          );
        } else if (isTwoPinch) {
          // 2핑거 핀치 시작: 클릭 대기
          _currentState = GestureState.twoPinch;
          _gestureStartPosition = pointerPosition;
          gesture = '2핑거 대기';
          debugPrint(
            '✋ 2-PINCH START at (${pointerPosition.dx.toStringAsFixed(2)}, ${pointerPosition.dy.toStringAsFixed(2)})',
          );
        } else {
          gesture = '손 감지됨';
        }
        break;

      case GestureState.twoPinch:
        if (isThreePinch) {
          // 2핑거 → 3핑거 전환 (중지 추가)
          _currentState = GestureState.threePinch;
          _gestureStartPosition = pointerPosition;
          gesture = '3핑거 대기';
          debugPrint('✋ 2-PINCH → 3-PINCH');
        } else if (!isTwoPinch) {
          // 핀치 해제 → 클릭!
          _currentState = GestureState.idle;
          _gestureStartPosition = null;
          gesture = '클릭!';
          debugPrint(
            '✋ CLICK at (${pointerPosition.dx.toStringAsFixed(2)}, ${pointerPosition.dy.toStringAsFixed(2)})',
          );
          _lastGestureTime = now;
        } else {
          // 2핑거 유지 중 - 이동 거리 확인
          final dx = pointerPosition.dx - _gestureStartPosition!.dx;
          final dy = pointerPosition.dy - _gestureStartPosition!.dy;
          final distance = dart_math.sqrt(dx * dx + dy * dy);

          if (distance > DRAG_THRESHOLD) {
            // 일정 거리 이상 이동 → 드래그 시작
            _currentState = GestureState.dragging;
            gesture = '드래그!';
            debugPrint('✋ DRAG START: distance=${distance.toStringAsFixed(3)}');
          } else {
            gesture = '2핑거 (떼면 클릭)';
          }
        }
        break;

      case GestureState.dragging:
        if (!isTwoPinch) {
          // 핀치 해제 → 드래그 종료
          _currentState = GestureState.idle;
          _gestureStartPosition = null;
          gesture = '드래그 완료';
          debugPrint('✋ DRAG END');
        } else {
          // 드래그 중 - 계속 위치 업데이트
          gesture = '드래그!';
        }
        break;

      case GestureState.threePinch:
        if (!isThreePinch && isTwoPinch) {
          // 3핑거 → 2핑거 전환 (중지 뗌)
          _currentState = GestureState.twoPinch;
          _gestureStartPosition = pointerPosition;
          gesture = '2핑거 (떼면 클릭)';
          debugPrint('✋ 3-PINCH → 2-PINCH');
        } else if (!isThreePinch && !isTwoPinch) {
          // 완전 해제 → idle로 복귀
          _currentState = GestureState.idle;
          _gestureStartPosition = null;
          gesture = '3핑거 해제';
          debugPrint('✋ 3-PINCH RELEASED');
        } else {
          // 3핑거 유지 중 - 이동 확인
          final dx = pointerPosition.dx - _gestureStartPosition!.dx;
          final dy = pointerPosition.dy - _gestureStartPosition!.dy;
          final distance = dart_math.sqrt(dx * dx + dy * dy);

          if (distance < DEADZONE_RADIUS) {
            // 떨림 방지 영역 내 - 대기
            gesture = '3핑거 대기';
          } else if (dx.abs() > dy.abs()) {
            // X축 우세 → 스와이프
            if (dx.abs() > SWIPE_THRESHOLD &&
                timeSinceLastGesture > SWIPE_COOLDOWN_MS) {
              gesture = dx > 0 ? '왼쪽 스와이프!' : '오른쪽 스와이프!';
              debugPrint(
                '✋ SWIPE ${dx > 0 ? "LEFT" : "RIGHT"}: dx=${dx.toStringAsFixed(3)}',
              );
              _lastGestureTime = now;
              _gestureStartPosition = pointerPosition; // 연속 스와이프 방지를 위해 위치 리셋
            } else {
              gesture = '좌우 이동 중...';
            }
          } else {
            // Y축 우세 → 스크롤
            _currentState = GestureState.scrolling;
            // 거리의 제곱에 비례하여 가속 (더 멀리 이동할수록 더 빠름)
            final absDistance = dy.abs();
            final acceleratedSpeed = dy * absDistance * SCROLL_SPEED_MULTIPLIER;
            gesture = '스크롤! (${acceleratedSpeed.toStringAsFixed(0)})';
            debugPrint(
              '✋ SCROLL: dy=${dy.toStringAsFixed(3)}, distance=${absDistance.toStringAsFixed(3)}, speed=${acceleratedSpeed.toStringAsFixed(1)}',
            );
          }
        }
        break;

      case GestureState.scrolling:
        if (!isThreePinch) {
          // 3핑거 해제 → idle로 복귀
          _currentState = GestureState.idle;
          _gestureStartPosition = null;
          gesture = '스크롤 완료';
          debugPrint('✋ SCROLL END');
        } else {
          // 계속 스크롤 중
          final dy = pointerPosition.dy - _gestureStartPosition!.dy;
          // 거리의 제곱에 비례하여 가속
          final absDistance = dy.abs();
          final acceleratedSpeed = dy * absDistance * SCROLL_SPEED_MULTIPLIER;
          gesture = '스크롤! (${acceleratedSpeed.toStringAsFixed(0)})';
          // 스크롤은 매 프레임마다 업데이트
        }
        break;

      case GestureState.voiceRecording:
        if (!isVoicePinch) {
          // 엄지+약지 해제 → 녹음 중지
          _currentState = GestureState.idle;
          _gestureStartPosition = null;
          gesture = '🛑 녹음 중지';
          debugPrint('🎤 VOICE RECORDING STOP');
        } else {
          // 계속 녹음 중
          gesture = '🎤 녹음 중';
        }
        break;
    }

    _lastLandmarks = landmarks;

    return HandDetectionResult(
      landmarks: landmarks,
      gesture: gesture,
      pointerPosition: pointerPosition,
      isCameraAtTop: isCameraAtTop,
      thumbTipPosition: null, // 더 이상 사용 안 함
      indexTipPosition: null, // 더 이상 사용 안 함
      gestureState: _currentState, // Add current pinch state
    );
  }

  void _resetGestureState() {
    _currentState = GestureState.idle;
    _gestureStartPosition = null;
    _lastSmoothedPosition = null;

    // 손이 감지되지 않을 때만 커서 안정화 상태 초기화
    _lastWristPosition = null;
    _stabilizedCursorPosition = null;
    _stabilityCounter = 0;
  }

  double _calculateDistance(HandLandmark p1, HandLandmark p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    final dz = p1.z - p2.z;
    return (dx * dx + dy * dy + dz * dz);
  }

  void dispose() {
    _subscription?.cancel();
    stopDetection();
  }
}
