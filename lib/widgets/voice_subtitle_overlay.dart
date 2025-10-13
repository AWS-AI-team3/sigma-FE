import 'package:flutter/material.dart';

class VoiceSubtitleOverlay extends StatelessWidget {
  final String subtitle;
  final bool isRecording;

  const VoiceSubtitleOverlay({
    super.key,
    required this.subtitle,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecording && subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.red.withOpacity(0.9)
              : Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Recording indicator
            if (isRecording) ...[
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Subtitle text
            Expanded(
              child: Text(
                subtitle.isEmpty ? '듣고 있습니다...' : subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
