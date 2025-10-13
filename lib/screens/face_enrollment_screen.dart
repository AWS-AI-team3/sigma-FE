import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/face_service.dart';
import '../mixins/camera_mixin.dart';
import '../widgets/face_back_button.dart';
import '../widgets/face_camera_widget.dart';
import '../widgets/face_camera_button.dart';
import '../widgets/face_dialog.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with CameraMixin, AutoCameraMixin {
  bool _isPhotoCaptured = false;
  Uint8List? _capturedImageBytes;
  bool _isProcessing = false;

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button
          FaceBackButton(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),

          // Title
          const Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '얼굴 등록하기',
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
                onConfirm: _handleRegister,
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

        print('📸 Face photo captured: ${imageBytes.length} bytes');
      }
    } catch (e) {
      print('❌ Photo capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 촬영에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_capturedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 사진을 촬영해주세요.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📤 Starting face enrollment...');

      // 1. Presigned URL 요청
      final presignResult = await FaceService.getPresignedUrl();

      if (presignResult == null || presignResult['sucess'] != true) {
        _showFailure();
        return;
      }

      final String presignedUrl = presignResult['data']['url'];
      final String contentType = presignResult['data']['contentType'];
      final String objectKey = presignResult['data']['objectKey'];

      // 2. S3 업로드
      final uploadSuccess = await FaceService.uploadImageToS3(
        presignedUrl,
        _capturedImageBytes!,
        contentType,
      );

      if (!uploadSuccess) {
        _showFailure();
        return;
      }

      // 3. 등록 완료 요청
      final completeResult =
          await FaceService.completeFaceRegistration(objectKey);

      if (completeResult != null && completeResult['sucess'] == true) {
        _showSuccess();
      } else {
        _showFailure();
      }
    } catch (error) {
      print('❌ Face enrollment error: $error');
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
      message: '얼굴 등록에 성공했습니다!',
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }

  void _showFailure() {
    FaceDialog.showFailure(
      context: context,
      message: '얼굴 등록에 실패했습니다!',
      onRetry: () {
        setState(() {
          _isPhotoCaptured = false;
          _capturedImageBytes = null;
        });
      },
    );
  }
}
