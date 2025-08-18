import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final VoidCallback? onCapture;
  final String? captureButtonText;
  final bool showCaptureButton;
  final Widget? overlay;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.onCapture,
    this.captureButtonText = '촬영',
    this.showCaptureButton = true,
    this.overlay,
  });

  Future<Uint8List?> _captureImage() async {
    if (controller == null || !controller!.value.isInitialized) return null;
    
    try {
      final XFile imageFile = await controller!.takePicture();
      return await imageFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // 카메라 프리뷰
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
        ),
        
        // 오버레이 (예: 얼굴 가이드)
        if (overlay != null) overlay!,
        
        // 촬영 버튼
        if (showCaptureButton)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: onCapture,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.camera_alt),
                label: Text(captureButtonText!),
              ),
            ),
          ),
      ],
    );
  }
}