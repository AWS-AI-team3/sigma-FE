import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/face_auth_service.dart';
import 'home_screen.dart';

class FaceAuthScreen extends StatefulWidget {
  const FaceAuthScreen({super.key});

  @override
  State<FaceAuthScreen> createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  final FaceAuthService _faceAuthService = FaceAuthService();
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isPhotoCaptured = false;
  Uint8List? _capturedImageBytes;
  String _statusMessage = '카메라를 준비 중입니다...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = await _faceAuthService.initializeCamera();

      if (controller != null && mounted) {
        setState(() {
          _cameraController = controller;
          _isInitialized = true;
          _statusMessage = '얼굴을 프레임 안에 맞춰주세요';
        });
      } else {
        setState(() {
          _statusMessage = '카메라를 사용할 수 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '카메라 초기화 오류: $e';
      });
    }
  }

  Future<void> _captureAndAuthenticate() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '사진을 촬영하는 중...';
    });

    try {
      // 사진 촬영
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      setState(() {
        _capturedImageBytes = bytes;
        _isPhotoCaptured = true;
        _statusMessage = '서버에 업로드 중...';
      });

      print('📸 Photo captured: ${bytes.length} bytes');

      // 1. Presigned URL 받기
      final presignedData = await _faceAuthService.getPresignedUrl();
      if (presignedData == null || presignedData['data'] == null) {
        throw Exception('Presigned URL을 받지 못했습니다');
      }

      final presignedUrl = presignedData['data']['presignedUrl'] as String;
      final authPhotoKey = presignedData['data']['authPhotokey'] as String;

      print('📡 Presigned URL received');
      print('🔑 Auth photo key: $authPhotoKey');

      // 2. S3에 이미지 업로드
      final uploadSuccess = await _faceAuthService.uploadImageToS3(
        presignedUrl,
        bytes,
      );

      if (!uploadSuccess) {
        throw Exception('이미지 업로드 실패');
      }

      print('✅ Image uploaded to S3');

      setState(() {
        _statusMessage = '얼굴 인증 중...';
      });

      // 3. 얼굴 인증 완료 요청
      final authResult = await _faceAuthService.completeFaceAuth(authPhotoKey);

      if (authResult == null || authResult['success'] != true) {
        final errorMessage = authResult?['error']?['message'] ?? '얼굴 인증 실패';
        throw Exception(errorMessage);
      }

      print('✅ Face authentication successful');

      setState(() {
        _statusMessage = '인증 성공!';
      });

      // 홈 화면으로 이동
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('❌ Face auth error: $e');
      setState(() {
        _statusMessage = '인증 실패: $e';
        _isProcessing = false;
        _isPhotoCaptured = false;
        _capturedImageBytes = null;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _isPhotoCaptured = false;
      _capturedImageBytes = null;
      _statusMessage = '얼굴을 프레임 안에 맞춰주세요';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade400, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '얼굴 인증',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 카메라 프리뷰 또는 촬영된 이미지
              Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: _isPhotoCaptured && _capturedImageBytes != null
                      ? Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
                      : _isInitialized && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // 상태 메시지
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // 버튼들
              if (_isProcessing)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              else if (_isPhotoCaptured)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _retakePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('다시 찍기'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _captureAndAuthenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('인증하기'),
                    ),
                  ],
                )
              else if (_isInitialized)
                ElevatedButton.icon(
                  onPressed: _captureAndAuthenticate,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('사진 촬영'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
