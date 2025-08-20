import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class SigmaBrandingText extends StatelessWidget {
  final String text;
  final String highlightLetters;
  final Color highlightColor;
  final TextStyle baseStyle;
  
  const SigmaBrandingText({
    super.key,
    required this.text,
    required this.highlightLetters,
    this.highlightColor = AppTheme.sigmaBlue,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    List<TextSpan> spans = [];
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isHighlight = highlightLetters.contains(char.toUpperCase());
      
      spans.add(TextSpan(
        text: char,
        style: baseStyle.copyWith(
          color: isHighlight ? highlightColor : Colors.black,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}