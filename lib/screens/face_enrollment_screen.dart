import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';
import 'dart:typed_data';
import '../services/face_service.dart';
import '../mixins/camera_mixin.dart';
import 'dart:math' as math;

enum EnrollmentStep {
  initial,      // face_enroll1 - 초기 화면
  scanning,     // face_enroll2 - 스캔 중
  success,      // face_enroll3 - 등록 성공
  failure,      // face_enroll4 - 등록 실패
}

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with CameraMixin, SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  EnrollmentStep _currentStep = EnrollmentStep.initial;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void onCameraInitialized() {
    print('✅ Face enrollment camera initialized');
  }

  @override
  void onCameraInitializeFailed(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카메라 초기화 실패: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9EA),
      body: Center(
        child: Container(
          width: 285,
          height: 419,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 35,
                offset: const Offset(3, 4),
              ),
            ],
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case EnrollmentStep.initial:
        return _buildInitialScreen();
      case EnrollmentStep.scanning:
        return _buildScanningScreen();
      case EnrollmentStep.success:
        return _buildSuccessScreen();
      case EnrollmentStep.failure:
        return _buildFailureScreen();
    }
  }

  // face_enroll1 - 초기 화면
  Widget _buildInitialScreen() {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 65),
            // Face avatar with circles
            SizedBox(
              width: 154,
              height: 154,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ellipse 5 (outer circle)
                  SvgPicture.asset(
                    'assets/images/face_enrollment/ellipse5.svg',
                    width: 152,
                    height: 152,
                  ),
                  // Ellipse 2 (inner circle)
                  SvgPicture.asset(
                    'assets/images/face_enrollment/ellipse2.svg',
                    width: 161,
                    height: 161,
                  ),
                  // Emoji placeholder
                  const Text(
                    '👨‍💼',
                    style: TextStyle(fontSize: 96),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            // Title
            const Text(
              '사용자 등록',
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 26),
            // Description line 1
            const Text(
              '얼굴을 등록 하여 2차 인증을 합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            // Description line 2
            const Text(
              '얼굴이 정면이 되게 유지해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 35),
            // Rectangle 14 button (Start button)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E9CFF),
                minimumSize: const Size(145, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.black.withOpacity(0.25),
                elevation: 8,
              ),
              onPressed: _onStartButtonPressed,
              child: const Text(
                '얼굴 등록 시작하기',
                style: TextStyle(
                  fontFamily: 'Apple SD Gothic Neo',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        // Exit bar (top-left)
        Positioned(
          left: 10,
          top: 10,
          child: SvgPicture.asset(
            'assets/images/face_enrollment/exit_bar.svg',
            width: 48,
            height: 12,
          ),
        ),
      ],
    );
  }

  // face_enroll2 - 스캔 중 화면
  Widget _buildScanningScreen() {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 82),
            // Camera preview with scanning animation
            SizedBox(
              width: 154,
              height: 154,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ellipse 2 - Camera preview area (140x140)
                  Positioned(
                    left: 7,
                    top: 7,
                    child: ClipOval(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: isCameraReady && cameraController != null
                            ? cameraController!.buildPreview()
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Ellipse 3 - Scanning ring animation
                  Transform.rotate(
                    angle: -math.pi / 2, // Start from top
                    child: CustomPaint(
                      size: const Size(154, 154),
                      painter: ScanningRingPainter(
                        progress: _animationController?.value ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            // Title
            const Text(
              '사용자 등록',
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 26),
            // Description line 1
            const Text(
              '얼굴을 등록 하여 2차 인증을 합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            // Description line 2
            const Text(
              '얼굴이 정면이 되게 유지해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Exit bar (top-left)
        Positioned(
          left: 10,
          top: 10,
          child: SvgPicture.asset(
            'assets/images/face_enrollment/exit_bar.svg',
            width: 48,
            height: 12,
          ),
        ),
      ],
    );
  }

  // face_enroll3 - 성공 화면
  Widget _buildSuccessScreen() {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success indicator
            SizedBox(
              width: 73,
              height: 73,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Success circle background
                  SvgPicture.asset(
                    'assets/images/face_enrollment/success_circle.svg',
                    width: 73,
                    height: 73,
                  ),
                  // Check icon
                  SvgPicture.asset(
                    'assets/images/face_enrollment/check_icon.svg',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Title
            const Text(
              '등록 완료',
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 26),
            // Description line 1
            const Text(
              '얼굴 등록이 완료되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            // Description line 2
            const Text(
              '등록된 얼굴로 2차 인증됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Exit bar (top-left)
        Positioned(
          left: 10,
          top: 10,
          child: SvgPicture.asset(
            'assets/images/face_enrollment/exit_bar.svg',
            width: 48,
            height: 12,
          ),
        ),
      ],
    );
  }

  // face_enroll4 - 실패 화면
  Widget _buildFailureScreen() {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Failure indicator
            SizedBox(
              width: 73,
              height: 73,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Failure circle background
                  SvgPicture.asset(
                    'assets/images/face_enrollment/failure_circle.svg',
                    width: 73,
                    height: 73,
                  ),
                  // Exclamation mark icon
                  SvgPicture.asset(
                    'assets/images/face_enrollment/exclamation_icon.svg',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Title
            const Text(
              '등록 실패',
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 26),
            // Description line 1
            const Text(
              '얼굴 등록에 실패하였습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            // Description line 2
            const Text(
              '재시도 하시기 바랍니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Apple SD Gothic Neo',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Exit bar (top-left)
        Positioned(
          left: 10,
          top: 10,
          child: SvgPicture.asset(
            'assets/images/face_enrollment/exit_bar.svg',
            width: 48,
            height: 12,
          ),
        ),
      ],
    );
  }

  // Rectangle 14 버튼 클릭 시 face_enroll2로 전환
  void _onStartButtonPressed() {
    if (!isCameraReady || cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 준비되지 않았습니다.')),
      );
      return;
    }

    setState(() {
      _currentStep = EnrollmentStep.scanning;
    });

    // Ellipse 3 애니메이션 시작 (3초)
    _animationController?.forward(from: 0).whenComplete(() {
      // 3초 후 카메라 촬영
      _captureAndEnroll();
    });
  }

  Future<void> _captureAndEnroll() async {
    try {
      final image = await cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      print('📸 Face photo captured: ${imageBytes.length} bytes');

      final enrollSuccess = await _enrollFace(imageBytes);

      if (enrollSuccess) {
        // 성공 시 face_enroll3로 전환
        setState(() {
          _currentStep = EnrollmentStep.success;
        });
        // 1초 후 다음 페이지로 이동
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      } else {
        // 실패 시 face_enroll4로 전환
        _showFailureAndReset();
      }
    } catch (e) {
      print('❌ Photo capture or enroll error: $e');
      _showFailureAndReset();
    }
  }

  Future<bool> _enrollFace(Uint8List imageBytes) async {
    try {
      print('📤 Starting face enrollment...');

      final presignResult = await FaceService.getPresignedUrl();
      if (presignResult == null || presignResult['sucess'] != true) {
        return false;
      }

      final String presignedUrl = presignResult['data']['url'];
      final String contentType = presignResult['data']['contentType'];
      final String objectKey = presignResult['data']['objectKey'];

      final uploadSuccess = await FaceService.uploadImageToS3(
        presignedUrl,
        imageBytes,
        contentType,
      );
      if (!uploadSuccess) return false;

      final completeResult = await FaceService.completeFaceRegistration(objectKey);
      return completeResult != null && completeResult['sucess'] == true;
    } catch (error) {
      print('❌ Face enrollment error: $error');
      return false;
    }
  }

  void _showFailureAndReset() {
    setState(() {
      _currentStep = EnrollmentStep.failure;
    });
    // 1초 후 초기 화면으로 복귀
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentStep = EnrollmentStep.initial;
          _animationController?.reset();
        });
      }
    });
  }
}

// Ellipse 3 스캔 애니메이션을 위한 CustomPainter
class ScanningRingPainter extends CustomPainter {
  final double progress;

  ScanningRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7; // Ellipse 2의 외곽을 따라 그리기

    // Green scanning ring
    final progressPaint = Paint()
      ..color = const Color(0xFF28A745)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // 3초 동안 한 바퀴 회전
    final double angle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // 시작 각도 (이미 Transform.rotate로 -90도 회전됨)
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScanningRingPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
