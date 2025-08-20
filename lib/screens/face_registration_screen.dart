import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_dashboard_screen.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/face_auth_service.dart';
import '../themes/app_theme.dart';
import '../widgets/safe_image_asset.dart';
import '../mixins/camera_mixin.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> with CameraMixin {
  bool _isPhotoCaptured = false;
  Uint8List? _capturedImageBytes;
  bool _isAuthenticating = false;
  
  // Presigned URL 데이터
  Map<String, dynamic>? _presignedData;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Arguments에서 presigned URL 데이터 받기
    _presignedData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void onCameraInitialized() {
    // 카메라 초기화 완료 시 추가 처리
  }

  @override
  void onCameraInitializeFailed(dynamic error) {
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
              onTap: () => Navigator.pop(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SafeIconImage(
                    assetPath: 'assets/images/back_fill.png',
                    size: 21,
                    fallbackIcon: Icons.arrow_back_ios,
                    color: AppTheme.sigmaLightBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'back',
                    style: AppTheme.sigmaBackButtonStyle,
                  ),
                ],
              ),
            ),
          ),
          
          // Title
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '얼굴 인증하기',
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
          
          // Camera button(s)
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
          onTap: _isAuthenticating ? null : _handleAuthenticate,
          child: _isAuthenticating
              ? const SizedBox(
                  width: 70,
                  height: 70,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sigmaLightBlue),
                    ),
                  ),
                )
              : Image.asset(
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
          onTap: _isAuthenticating ? null : _handleRetake,
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
        
        // 디버그: 촬영된 이미지 정보 출력
        print('촬영된 이미지 크기: ${imageBytes.length} bytes');
        print('촬영된 이미지 경로: ${image.path}');
        
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

  void _handleAuthenticate() async {
    if (_capturedImageBytes != null && _presignedData != null) {
      setState(() {
        _isAuthenticating = true;
      });
      
      try {
        print('인증용 이미지 준비됨 - S3 업로드 시작 (${_capturedImageBytes!.length} bytes)');
        
        final String presignedUrl = _presignedData!['url'];
        final String contentType = _presignedData!['contentType'];
        final String objectKey = _presignedData!['objectKey'];
        
        // S3에 이미지 업로드
        final uploadSuccess = await FaceAuthService.uploadAuthImageToS3(
          presignedUrl, 
          _capturedImageBytes!, 
          contentType
        );
        
        if (!uploadSuccess) {
          _showAuthenticationFailureDialog(context);
          return;
        }
        
        // 얼굴 인증 완료 요청
        final authResult = await FaceAuthService.completeFaceAuth(objectKey);
        
        if (authResult != null && (authResult['sucess'] == true || authResult['success'] == true)) {
          _showAuthenticationSuccessDialog(context);
        } else {
          _showAuthenticationFailureDialog(context);
        }
        
      } catch (error) {
        print('얼굴 인증 오류: $error');
        _showAuthenticationFailureDialog(context);
      } finally {
        if (mounted) {
          setState(() {
            _isAuthenticating = false;
          });
        }
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
    });
  }

  void _showAuthenticationSuccessDialog(BuildContext dialogContext) {
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
                    Image.asset(
                      'assets/images/check_fill.png',
                      width: 60,
                      height: 60,
                      color: AppTheme.sigmaLightBlue,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.check,
                          size: 60,
                          color: AppTheme.sigmaLightBlue,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '얼굴 인증에 성공했습니다!',
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
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
                                  color: AppTheme.sigmaLightBlue,
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

  void _showAuthenticationFailureDialog(BuildContext dialogContext) {
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
                    Image.asset(
                      'assets/images/x_fill.png',
                      width: 60,
                      height: 60,
                      color: AppTheme.sigmaLightBlue,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.close,
                          size: 60,
                          color: AppTheme.sigmaLightBlue,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '얼굴 인증에 실패했습니다!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                                  color: AppTheme.sigmaLightBlue,
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
