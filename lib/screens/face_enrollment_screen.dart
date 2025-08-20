import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_loading_screen.dart';
import 'login_screen.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/face_service.dart';
import '../themes/app_theme.dart';
import '../mixins/camera_mixin.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> with CameraMixin, AutoCameraMixin {
  bool _isPhotoCaptured = false;
  Uint8List? _capturedImageBytes;

  @override
  void onCameraInitialized() {
    // 카메라 초기화 완료 시 추가 처리가 필요하면 여기에 구현
  }

  @override
  void onCameraInitializeFailed(dynamic error) {
    // 카메라 초기화 실패 시 사용자에게 알림 등 처리
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카메라 초기화에 실패했습니다: $error'),
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
          // Back button and arrow
          Positioned(
            top: 55,
            left: 55,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/back_fill.png',
                    width: 21,
                    height: 21,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.sigmaLightBlue,
                        size: 21,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'back',
                    style: const TextStyle(
                      fontFamily: 'AppleSDGothicNeo',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.sigmaLightBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Title
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '얼굴 등록하기',
                style: const TextStyle(
                  fontFamily: 'AppleSDGothicNeo',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          
          // Camera area
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 377,
                height: 377,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _buildCameraPreview(),
              ),
            ),
          ),
          
          // Camera button
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCameraButtons(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCameraPreview() {
    if (_isPhotoCaptured && _capturedImageBytes != null) {
      // 촬영된 이미지 표시 (좌우반전, 가운데 정렬)
      return Container(
        width: 377,
        height: 377,
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Transform.scale(
            scaleX: -1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.memory(
                _capturedImageBytes!,
                width: 377,
                height: 377,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }

    if (isCameraReady && cameraController != null) {
      // 디버그: 카메라 해상도 출력
      final previewSize = cameraController!.value.previewSize!;
      print('카메라 프리뷰 해상도: ${previewSize.width}x${previewSize.height}');
      print('카메라 종횡비: ${cameraController!.value.aspectRatio}');
      
      // 실시간 카메라 프리뷰 (가운데 정렬)
      return Container(
        width: 377,
        height: 377,
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              width: 377,
              height: 377,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize!.height,
                  height: cameraController!.value.previewSize!.width,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 카메라 로딩 중일 때
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.sigmaLightBlue,
      ),
    );
  }

  Widget _buildCameraButtons() {
    if (!_isPhotoCaptured) {
      return GestureDetector(
        onTap: _handleTakePhoto,
        child: Image.asset(
          'assets/images/camera.png',
          width: 70,
          height: 70,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppTheme.sigmaLightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _handleRegister,
          child: Image.asset(
            'assets/images/check.png',
            width: 70,
            height: 70,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppTheme.sigmaLightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: _handleRetake,
          child: Image.asset(
            'assets/images/reload.png',
            width: 70,
            height: 70,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppTheme.sigmaLightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleTakePhoto() async {
    try {
      if (cameraController != null && isCameraReady) {
        final image = await cameraController!.takePicture();
        final imageBytes = await image.readAsBytes();
        setState(() {
          _capturedImageBytes = imageBytes;
          _isPhotoCaptured = true;
        });
        print('이미지 촬영 완료 - 메모리에 저장됨 (${imageBytes.length} bytes)');
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 촬영에 실패했습니다.')),
      );
    }
  }

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
      // 카메라는 이미 초기화되어 있으므로 재초기화하지 않음
    });
  }

  void _showEnrollmentFailureDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayBackground.withValues(alpha: 0.75),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.dialogGray,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.close,
                      size: 60,
                      color: AppTheme.buttonBlue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '얼굴 등록에 실패했습니다!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isPhotoCaptured = false;
                          _capturedImageBytes = null;
                        });
                      },
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/rectangle.png',
                            width: 80,
                            height: 35,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: AppTheme.buttonBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                'okay',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
  void _showEnrollmentSuccessDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayBackground.withValues(alpha: 0.75),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.dialogGray,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 60,
                      color: AppTheme.buttonBlue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '얼굴 등록에 성공했습니다!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        LoginLoadingScreenState.setUserRegistered();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/rectangle.png',
                            width: 80,
                            height: 35,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: AppTheme.buttonBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                'okay',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}
