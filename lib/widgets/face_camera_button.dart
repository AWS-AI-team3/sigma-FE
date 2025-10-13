import 'package:flutter/material.dart';

/// 얼굴 촬영 버튼 (공통)
class FaceCameraButton extends StatelessWidget {
  final bool isPhotoCaptured;
  final bool isProcessing;
  final VoidCallback onCapture;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const FaceCameraButton({
    super.key,
    required this.isPhotoCaptured,
    required this.isProcessing,
    required this.onCapture,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPhotoCaptured) {
      // 촬영 버튼
      return _buildCameraIcon(onCapture);
    }

    // 확인 + 재촬영 버튼
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isProcessing
            ? const SizedBox(
                width: 70,
                height: 70,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
            : _buildCheckIcon(onConfirm),
        const SizedBox(width: 40),
        if (!isProcessing) _buildRetakeIcon(onRetake),
      ],
    );
  }

  Widget _buildCameraIcon(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildCheckIcon(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildRetakeIcon(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.refresh, color: Colors.white, size: 30),
      ),
    );
  }
}
