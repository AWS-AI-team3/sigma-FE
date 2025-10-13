import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

/// 얼굴 촬영용 카메라 위젯 (공통)
class FaceCameraWidget extends StatelessWidget {
  final bool isPhotoCaptured;
  final Uint8List? capturedImageBytes;
  final bool isCameraReady;
  final CameraController? cameraController;

  const FaceCameraWidget({
    super.key,
    required this.isPhotoCaptured,
    required this.capturedImageBytes,
    required this.isCameraReady,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 377,
      height: 377,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // 촬영된 이미지 표시
    if (isPhotoCaptured && capturedImageBytes != null) {
      return Center(
        child: Transform.scale(
          scaleX: -1, // 좌우 반전
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.memory(
              capturedImageBytes!,
              width: 377,
              height: 377,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // 카메라 프리뷰
    if (isCameraReady && cameraController != null) {
      return Center(
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
      );
    }

    // 로딩 중
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.blue,
      ),
    );
  }
}
