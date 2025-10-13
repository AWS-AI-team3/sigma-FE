import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:typed_data';
import '../services/face_auth_service.dart';
import '../mixins/camera_mixin.dart';
import '../widgets/face_back_button.dart';
import '../widgets/face_camera_widget.dart';
import '../widgets/face_camera_button.dart';
import '../widgets/face_dialog.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen>
    with CameraMixin {
  bool _isPhotoCaptured = false;
  Uint8List? _capturedImageBytes;
  bool _isProcessing = false;

  Map<String, dynamic>? _presignedData;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presignedData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void onCameraInitialized() {
    print('✅ Face registration camera initialized');
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button
          FaceBackButton(onTap: () => Navigator.pop(context)),

          // Title
          const Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '얼굴 인증하기',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Camera preview
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: FaceCameraWidget(
                isPhotoCaptured: _isPhotoCaptured,
                capturedImageBytes: _capturedImageBytes,
                isCameraReady: isCameraReady,
                cameraController: cameraController,
              ),
            ),
          ),

          // Camera buttons
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: FaceCameraButton(
                isPhotoCaptured: _isPhotoCaptured,
                isProcessing: _isProcessing,
                onCapture: _handleTakePhoto,
                onConfirm: _handleAuthenticate,
                onRetake: _handleRetake,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTakePhoto() async {
    try {
      if (cameraController != null && isCameraReady) {
        final image = await cameraController!.takePicture();
        final imageBytes = await image.readAsBytes();

        setState(() {
          _capturedImageBytes = imageBytes;
          _isPhotoCaptured = true;
        });

        print('📸 Face auth photo captured: ${imageBytes.length} bytes');
      }
    } catch (e) {
      print('❌ Photo capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진 촬영에 실패했습니다.')));
      }
    }
  }

  Future<void> _handleAuthenticate() async {
    if (_capturedImageBytes == null || _presignedData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 사진을 촬영해주세요.')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📤 Starting face authentication...');

      final String presignedUrl = _presignedData!['url'];
      final String contentType = _presignedData!['contentType'];
      final String objectKey = _presignedData!['objectKey'];

      // S3 업로드
      final uploadSuccess = await FaceAuthService.uploadAuthImageToS3(
        presignedUrl,
        _capturedImageBytes!,
        contentType,
      );

      if (!uploadSuccess) {
        _showFailure();
        return;
      }

      // 인증 완료 요청
      final authResult = await FaceAuthService.completeFaceAuth(objectKey);

      if (authResult != null &&
          (authResult['sucess'] == true || authResult['success'] == true)) {
        _showSuccess();
      } else {
        _showFailure();
      }
    } catch (error) {
      print('❌ Face authentication error: $error');
      _showFailure();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleRetake() {
    setState(() {
      _isPhotoCaptured = false;
      _capturedImageBytes = null;
    });
  }

  void _showSuccess() {
    FaceDialog.showSuccess(
      context: context,
      message: '얼굴 인증에 성공했습니다!',
      onConfirm: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
    );
  }

  void _showFailure() {
    FaceDialog.showFailure(
      context: context,
      message: '얼굴 인증에 실패했습니다!',
      onRetry: () {
        setState(() {
          _isPhotoCaptured = false;
          _capturedImageBytes = null;
        });
      },
    );
  }
}
