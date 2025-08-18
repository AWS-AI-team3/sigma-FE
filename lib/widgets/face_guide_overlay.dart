import 'package:flutter/material.dart';

class FaceGuideOverlay extends StatelessWidget {
  final String? instructionText;
  final bool showGuide;

  const FaceGuideOverlay({
    super.key,
    this.instructionText,
    this.showGuide = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showGuide) return const SizedBox.shrink();

    return Stack(
      children: [
        // 얼굴 가이드 원형
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
          ),
        ),
        
        // 안내 텍스트
        if (instructionText != null)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                instructionText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}