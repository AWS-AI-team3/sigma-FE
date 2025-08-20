import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBackgroundColor;
  final bool isCircular;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.fallback,
    this.fallbackIcon,
    this.fallbackColor,
    this.fallbackBackgroundColor,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );

    if (isCircular) {
      return ClipOval(child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    if (fallback != null) {
      return fallback!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fallbackBackgroundColor ?? Colors.grey,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        fallbackIcon ?? Icons.person,
        color: fallbackColor ?? Colors.white,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.5 : height! * 0.5) 
            : 30,
      ),
    );
  }
}

// 프로필 이미지 전용 위젯
class SafeProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const SafeProfileImage({
    super.key,
    this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: size * 0.5,
        ),
      );
    }

    return SafeNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      isCircular: true,
      fallbackIcon: Icons.person,
      fallbackColor: Colors.white,
      fallbackBackgroundColor: Colors.grey,
    );
  }
}