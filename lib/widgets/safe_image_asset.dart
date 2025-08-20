import 'package:flutter/material.dart';

class SafeImageAsset extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBackgroundColor;
  final String? fallbackText;

  const SafeImageAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
    this.fallback,
    this.fallbackIcon,
    this.fallbackColor,
    this.fallbackBackgroundColor,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (fallback != null) {
          return fallback!;
        }

        // 기본 fallback 생성
        return _buildDefaultFallback();
      },
    );
  }

  Widget _buildDefaultFallback() {
    if (fallbackText != null) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(
          fallbackText!,
          style: const TextStyle(
            fontFamily: 'AppleSDGothicNeo',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFB2B0B0),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fallbackBackgroundColor ?? Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Icon(
        fallbackIcon ?? Icons.image,
        color: fallbackColor ?? Colors.white,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.6 : height! * 0.6) 
            : 24,
      ),
    );
  }
}

// 특화된 이미지 위젯들
class SafeLogoImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final String? fallbackText;

  const SafeLogoImage({
    super.key,
    required this.assetPath,
    required this.size,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeImageAsset(
      assetPath: assetPath,
      width: size,
      height: size,
      fallbackText: fallbackText,
    );
  }
}

class SafeIconImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final IconData fallbackIcon;
  final Color? color;

  const SafeIconImage({
    super.key,
    required this.assetPath,
    required this.size,
    required this.fallbackIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SafeImageAsset(
      assetPath: assetPath,
      width: size,
      height: size,
      fallbackIcon: fallbackIcon,
      fallbackColor: color ?? const Color(0xFF5381F6),
    );
  }
}