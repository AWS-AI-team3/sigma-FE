import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigma_flutter_ui/screens/login_loading_screen.dart';
import 'package:sigma_flutter_ui/screens/login_screen.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
<<<<<<< HEAD
import '../services/face_service.dart';
import '../services/camera_manager.dart';
=======
>>>>>>> round_camera

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  bool _isPhotoCaptured = false;
  CameraController? _controller;
<<<<<<< HEAD
  bool _isCameraReady = false;
=======
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
>>>>>>> round_camera
  Uint8List? _capturedImageBytes;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
<<<<<<< HEAD
    // 화면을 떠날 때 카메라 해제
    CameraManager.instance.dispose();
=======
    _controller?.dispose();
>>>>>>> round_camera
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
<<<<<<< HEAD
      _controller = await CameraManager.instance.initializeCamera();
      if (mounted && _controller != null) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
=======
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        CameraDescription? frontCamera;
        for (final camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }
        final selectedCamera = frontCamera ?? cameras.first;
        _controller = CameraController(
          selectedCamera,
          ResolutionPreset.medium,
        );
        _initializeControllerFuture = _controller!.initialize();
        await _initializeControllerFuture;

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
>>>>>>> round_camera
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                children: [
<<<<<<< HEAD
                  _buildTitle(),
=======
                  _buildBannerImage(), // <-- 타이틀 배너 자리에 이미지 삽입
>>>>>>> round_camera
                  const SizedBox(height: 30),
                  Expanded(
                    child: _buildCameraArea(),
                  ),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 120,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
<<<<<<< HEAD
              // 로그인 화면으로 돌아가기 (모든 이전 화면 제거)
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
=======
              Navigator.of(context).pop();
>>>>>>> round_camera
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_ios, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildTitle() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFB6A0F3),
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 20),
          Text(
            '얼굴 등록하기',
            style: GoogleFonts.roboto(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
=======
  // 배너 위치에 enroll.png 이미지를 보라색 배경 위에 표시
  Widget _buildBannerImage() {
    return SizedBox(
      height : 55,
      width: double.infinity,
      child: Image.asset(
        'assets/images/enroll_no.png',
        fit: BoxFit.cover,
>>>>>>> round_camera
      ),
    );
  }

  Widget _buildCameraArea() {
<<<<<<< HEAD
    return Container(
      width: 400, // 최대 너비 제한
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: _buildCameraPlaceholder(),
=======
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF3B82F6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _buildCameraPlaceholder(),
        ),
>>>>>>> round_camera
      ),
    );
  }

<<<<<<< HEAD

Widget _buildCameraPlaceholder() {
    // 촬영된 이미지가 있으면 그것을 표시
    if (_isPhotoCaptured && _capturedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0), // 좌우 반전
          child: AspectRatio(
            aspectRatio: _controller?.value.aspectRatio ?? (4/3),
=======
  Widget _buildCameraPlaceholder() {
    if (_isPhotoCaptured && _capturedImageBytes != null) {
      return ClipOval(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
>>>>>>> round_camera
            child: Image.memory(
              _capturedImageBytes!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

<<<<<<< HEAD
    if (!_isCameraReady || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF1F5F9),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                strokeWidth: 3.0,
              ),
              SizedBox(height: 20),
              Text(
                '카메라를 초기화하는 중...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
=======
    if (!_isCameraInitialized || _controller == null) {
      return ClipOval(
        child: Container(
          width: 280,
          height: 280,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 3.0,
            ),
>>>>>>> round_camera
          ),
        ),
      );
    }

<<<<<<< HEAD
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
=======
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ClipOval(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AspectRatio(
                aspectRatio: 1,
                child: CameraPreview(_controller!),
              ),
            ),
          );
        } else {
          return ClipOval(
            child: Container(
              width: 280,
              height: 280,
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  strokeWidth: 3.0,
                ),
              ),
            ),
          );
        }
      },
>>>>>>> round_camera
    );
  }

  Widget _buildActionButtons() {
    if (!_isPhotoCaptured) {
      return Container(
        width: 295,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFCADDFF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleTakePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCADDFF),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            '촬영하기',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '등록하기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleRetake,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '다시찍기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTakePhoto() async {
    try {
<<<<<<< HEAD
      if (_controller != null && _isCameraReady) {
        final image = await _controller!.takePicture();
        final imageBytes = await image.readAsBytes();
        
=======
      if (_controller != null && _isCameraInitialized) {
        final image = await _controller!.takePicture();
        final imageBytes = await image.readAsBytes();

>>>>>>> round_camera
        setState(() {
          _capturedImageBytes = imageBytes;
          _isPhotoCaptured = true;
        });
<<<<<<< HEAD
        
=======

>>>>>>> round_camera
        print('이미지 촬영 완료 - 메모리에 저장됨 (${imageBytes.length} bytes)');
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 촬영에 실패했습니다.')),
      );
    }
  }

<<<<<<< HEAD
  void _handleRegister() async {
    if (_capturedImageBytes != null) {
      print('등록용 이미지 준비됨 - presigned S3 업로드 시작 (${_capturedImageBytes!.length} bytes)');
      
      try {
        // 1. Presigned URL 요청
        final presignResult = await FaceService.getPresignedUrl();
        
        if (presignResult == null || presignResult['sucess'] != true) {
          _showEnrollmentFailureDialog(context);
          return;
        }
        
        final String presignedUrl = presignResult['data']['url'];
        final String contentType = presignResult['data']['contentType'];
        final String objectKey = presignResult['data']['objectKey'];
        
        // 2. S3에 이미지 업로드
        final uploadSuccess = await FaceService.uploadImageToS3(
          presignedUrl, 
          _capturedImageBytes!, 
          contentType
        );
        
        if (!uploadSuccess) {
          _showEnrollmentFailureDialog(context);
          return;
        }
        
        // 3. 얼굴 등록 완료 요청
        final completeResult = await FaceService.completeFaceRegistration(objectKey);
        
        if (completeResult != null && completeResult['sucess'] == true) {
          _showEnrollmentSuccessDialog(context);
        } else {
          _showEnrollmentFailureDialog(context);
        }
        
      } catch (error) {
        print('얼굴 등록 오류: $error');
        _showEnrollmentFailureDialog(context);
      }
=======
  void _handleRegister() {
    if (_capturedImageBytes != null) {
      print('등록용 이미지 준비됨 - presigned S3 업로드 예정 (${_capturedImageBytes!.length} bytes)');
      // presigned S3 업로드 로직 추가 가능
      _showEnrollmentSuccessDialog(context);
>>>>>>> round_camera
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 사진을 촬영해주세요.')),
      );
    }
  }

  void _handleRetake() {
    setState(() {
      _isPhotoCaptured = false;
<<<<<<< HEAD
      _capturedImageBytes = null; // 메모리에서 이미지 제거
      // 카메라는 이미 초기화되어 있으므로 재초기화하지 않음
    });
  }

  void _showEnrollmentFailureDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF44336),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      '얼굴 등록에 실패했습니다!\n다시 촬영해주세요.',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // 다시 촬영할 수 있도록 상태 초기화 (카메라는 유지)
                          setState(() {
                            _isPhotoCaptured = false;
                            _capturedImageBytes = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

=======
      _capturedImageBytes = null;
    });
  }

>>>>>>> round_camera
  void _showEnrollmentSuccessDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      '얼굴 등록에 성공했습니다!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          LoginLoadingScreenState.setUserRegistered();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======


>>>>>>> round_camera
