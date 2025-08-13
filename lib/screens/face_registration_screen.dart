import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigma_flutter_ui/screens/main_dashboard_screen.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool _isPhotoCaptured = false;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  Uint8List? _capturedImageBytes;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // 전면 카메라 찾기 (얼굴 인증용)
        CameraDescription? frontCamera;
        for (final camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }
        
        // 전면 카메라가 없으면 첫 번째 카메라 사용
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
          print('카메라 비율: ${_controller!.value.aspectRatio}');
          print('카메라 해상도: ${_controller!.value.previewSize}');
        }
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
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
                  _buildTitle(),
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
              Navigator.of(context).pop();
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
            '얼굴 인증하기',
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
      ),
    );
  }

  Widget _buildCameraArea() {
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
      ),
    );
  }

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
            child: Image.memory(
              _capturedImageBytes!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
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
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          );
        } else {
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
                    '얼굴을 화면에 맞춰주세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
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
              fontSize: 15,
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
            onPressed: _handleAuthenticate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '인증하기',
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
      if (_controller != null && _isCameraInitialized) {
        final image = await _controller!.takePicture();
        final imageBytes = await image.readAsBytes();
        
        setState(() {
          _capturedImageBytes = imageBytes;
          _isPhotoCaptured = true;
        });
        
        print('이미지 촬영 완료 - 메모리에 저장됨 (${imageBytes.length} bytes)');
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 촬영에 실패했습니다.')),
        );
      }
    }
  }

  void _handleAuthenticate() {
    if (_capturedImageBytes != null) {
      print('인증용 이미지 준비됨 - 서버 인증 예정 (${_capturedImageBytes!.length} bytes)');
      // TODO: 여기에 서버 얼굴 인증 로직 추가
      _showAuthenticationSuccessDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 사진을 촬영해주세요.')),
      );
    }
  }

  void _handleRetake() {
    setState(() {
      _isPhotoCaptured = false;
      _capturedImageBytes = null; // 메모리에서 이미지 제거
    });
  }

  void _showAuthenticationSuccessDialog(BuildContext dialogContext) {
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
                      '얼굴 인증에 성공했습니다!',
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
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