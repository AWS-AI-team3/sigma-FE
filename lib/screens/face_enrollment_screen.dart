import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:typed_data';
import '../services/face_service.dart';
import '../services/google_auth_service.dart';
import '../mixins/camera_mixin.dart';
import 'dart:math' as math;

enum EnrollmentStep {
  initial, // face_enroll1 - 초기 화면
  scanning, // face_enroll2 - 스캔 중
  success, // face_enroll3 - 등록 성공
  failure, // face_enroll4 - 등록 실패
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
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
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
    // Figma frame: 836x584, Card: 285x419
    // Scale to match iPad screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 836; // Figma frame width

    final cardWidth = 285 * scale;
    final cardHeight = 419 * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9EA),
      body: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 35 * scale,
                offset: Offset(3 * scale, 4 * scale),
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(width: 285, height: 419, child: _buildContent()),
          ),
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
        // Exit bar - Figma: left=10, top=10 (48x12 with 3 circles)
        Positioned(
          left: 10,
          top: 10,
          child: SizedBox(
            width: 48,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 종료 button (red) - logout and returns to login screen
                GestureDetector(
                  onTap: () async {
                    final authService = GoogleAuthService();
                    await authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFE5F57),
                    ),
                  ),
                ),
                // 숨기기 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
                // 전체화면 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Face avatar - Figma: left=63, top=65, size=154x154
        Positioned(
          left: 63,
          top: 65,
          child: SizedBox(
            width: 154,
            height: 154,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera preview (140x140 circle)
                ClipOval(
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
                // Ellipse 5 - Green border circle (154x154, stroke 4px)
                Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF27C841), // rgb(39, 200, 65)
                      width: 4.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Text group - Figma: left=62 (centered), top=243
        Positioned(
          left: 62,
          top: 245,
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                // Title
                const Text(
                  '사용자 등록',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Apple SD Gothic Neo',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 4),
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
          ),
        ),
        // Button - Figma: left=70, top=324, size=145x34
        Positioned(
          left: 70,
          top: 324,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4E9CFF),
              minimumSize: const Size(145, 34),
              maximumSize: const Size(145, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.25),
              elevation: 8,
              padding: EdgeInsets.zero,
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
        ),
      ],
    );
  }

  // face_enroll2 - 스캔 중 화면
  Widget _buildScanningScreen() {
    return Stack(
      children: [
        // Exit bar - Figma: left=10, top=10 (48x12 with 3 circles)
        Positioned(
          left: 10,
          top: 10,
          child: SizedBox(
            width: 48,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 종료 button (red) - logout and returns to login screen
                GestureDetector(
                  onTap: () async {
                    final authService = GoogleAuthService();
                    await authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFE5F57),
                    ),
                  ),
                ),
                // 숨기기 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
                // 전체화면 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Camera preview area - Figma: left=70, top=88 (Ellipse 2: 140x140)
        Positioned(
          left: 70,
          top: 88,
          child: ClipOval(
            child: SizedBox(
              width: 140,
              height: 140,
              child: isCameraReady && cameraController != null
                  ? cameraController!.buildPreview()
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
        ),
        // Ellipse 3 - Scanning ring animation (154x154, same as Ellipse 5)
        // Figma: left=63, top=82
        Positioned(
          left: 63,
          top: 82,
          child: Transform.rotate(
            angle: -math.pi / 2, // Start from top
            child: CustomPaint(
              size: const Size(154, 154),
              painter: ScanningRingPainter(
                progress: _animationController?.value ?? 0,
              ),
            ),
          ),
        ),
        // Text group - Figma: left=62, top=243 (keeping same as initial screen)
        Positioned(
          left: 62,
          top: 243,
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                // Title
                const Text(
                  '사용자 등록',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Apple SD Gothic Neo',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 4),
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
          ),
        ),
      ],
    );
  }

  // face_enroll3 - 성공 화면
  Widget _buildSuccessScreen() {
    return Stack(
      children: [
        // Exit bar - Figma: left=10, top=10 (48x12 with 3 circles)
        Positioned(
          left: 10,
          top: 10,
          child: SizedBox(
            width: 48,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 종료 button (red) - logout and returns to login screen
                GestureDetector(
                  onTap: () async {
                    final authService = GoogleAuthService();
                    await authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFE5F57),
                    ),
                  ),
                ),
                // 숨기기 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
                // 전체화면 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Success indicator - Figma: left=108, top=122, size=73x73
        Positioned(
          left: 108,
          top: 122,
          child: SizedBox(
            width: 73,
            height: 73,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ellipse 4 - Success circle background
                Container(
                  width: 73,
                  height: 73,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF27C841), // Green
                      width: 4.0,
                    ),
                  ),
                ),
                // Check icon - 50x50
                Icon(Icons.check, size: 40, color: const Color(0xFF27C841)),
              ],
            ),
          ),
        ),
        // Text group - Figma: left=62, top=284
        Positioned(
          left: 62,
          top: 284,
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                // Title
                const Text(
                  '등록 완료',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Apple SD Gothic Neo',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 4),
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
          ),
        ),
      ],
    );
  }

  // face_enroll4 - 실패 화면
  Widget _buildFailureScreen() {
    return Stack(
      children: [
        // Exit bar - Figma: left=10, top=10 (48x12 with 3 circles)
        Positioned(
          left: 10,
          top: 10,
          child: SizedBox(
            width: 48,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 종료 button (red) - logout and returns to login screen
                GestureDetector(
                  onTap: () async {
                    final authService = GoogleAuthService();
                    await authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFE5F57),
                    ),
                  ),
                ),
                // 숨기기 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
                // 전체화면 button (gray)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDADADB),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Failure indicator - Figma: left=105, top=122, size=76x73
        Positioned(
          left: 105,
          top: 122,
          child: SizedBox(
            width: 76,
            height: 73,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // face_signup - Red circle background
                Positioned(
                  left: 1.5,
                  child: Container(
                    width: 73,
                    height: 73,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDC3545), // Red
                        width: 4.0,
                      ),
                    ),
                  ),
                ),
                // Exclamation mark icon - 50x50
                SvgPicture.asset(
                  'assets/images/face_enrollment/exclamation_icon.svg',
                  width: 50,
                  height: 50,
                ),
              ],
            ),
          ),
        ),
        // Text group - Figma: left=62, top=284
        Positioned(
          left: 62,
          top: 284,
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                // Title
                const Text(
                  '등록 실패',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Apple SD Gothic Neo',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 4),
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
          ),
        ),
      ],
    );
  }

  // Rectangle 14 버튼 클릭 시 face_enroll2로 전환
  void _onStartButtonPressed() {
    if (!isCameraReady || cameraController == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카메라가 준비되지 않았습니다.')));
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
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
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
      print('📏 Image size: ${imageBytes.length} bytes');

      final presignResult = await FaceService.getPresignedUrl();
      print('📨 Presign result: $presignResult');

      if (presignResult == null || presignResult['sucess'] != true) {
        print('❌ Failed to get presigned URL');
        print('   Result is null: ${presignResult == null}');
        print('   Success flag: ${presignResult?['sucess']}');
        return false;
      }

      final String presignedUrl = presignResult['data']['url'];
      final String contentType = presignResult['data']['contentType'];
      final String objectKey = presignResult['data']['objectKey'];

      print('✅ Got presigned URL');
      print('   Content-Type: $contentType');
      print('   Object Key: $objectKey');

      final uploadSuccess = await FaceService.uploadImageToS3(
        presignedUrl,
        imageBytes,
        contentType,
      );

      if (!uploadSuccess) {
        print('❌ S3 upload failed');
        return false;
      }

      print('✅ S3 upload successful, completing registration...');
      final completeResult = await FaceService.completeFaceRegistration(
        objectKey,
      );
      print('📨 Complete result: $completeResult');

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
// Ellipse 5와 동일한 크기 (154x154), stroke 4px, 녹색
class ScanningRingPainter extends CustomPainter {
  final double progress;

  ScanningRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2; // stroke 4px의 절반 고려

    // Green scanning ring - Figma color: rgb(39, 200, 65)
    final progressPaint = Paint()
      ..color = const Color(0xFF27C841)
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
