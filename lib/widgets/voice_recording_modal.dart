import 'package:flutter/material.dart';

class VoiceRecordingModal extends StatelessWidget {
  final String? transcription;

  const VoiceRecordingModal({super.key, this.transcription});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 836; // iPad scale

    final bool hasText = transcription != null && transcription!.isNotEmpty;

    // Calculate width based on transcription presence
    double modalWidth;
    if (hasText) {
      // Calculate text width with padding
      final textPainter = TextPainter(
        text: TextSpan(
          text: transcription,
          style: TextStyle(
            fontFamily: 'Apple SD Gothic Neo',
            fontWeight: FontWeight.w700,
            fontSize: 10 * scale,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Width = left padding (12) + icon (22) + spacing (12) + text width + right padding (12)
      modalWidth = (12 + 22 + 12 + textPainter.width + 12) * scale;
    } else {
      // Icon only: just wrap the icon tightly with padding
      // Width = left padding (12) + icon (22) + right padding (12) = 46
      modalWidth = 46 * scale;
    }

    return Center(
      child: Container(
        width: modalWidth,
        height: 35 * scale,
        decoration: BoxDecoration(
          color: const Color(0x85505054), // #50505485 with 0.9 opacity
          borderRadius: BorderRadius.circular(20 * scale),
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000), // 25% black
              offset: Offset(3 * scale, 4 * scale),
              blurRadius: 35 * scale,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 12 * scale),
            // Voice icon - using graphic_eq for waveform effect
            Icon(
              Icons.graphic_eq_rounded,
              size: 22 * scale,
              color: Colors.white,
            ),
            if (hasText) ...[
              SizedBox(width: 12 * scale),
              Flexible(
                child: Text(
                  transcription!,
                  style: TextStyle(
                    fontFamily: 'Apple SD Gothic Neo',
                    fontWeight: FontWeight.w700,
                    fontSize: 10 * scale,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            SizedBox(width: 12 * scale),
          ],
        ),
      ),
    );
  }
}
