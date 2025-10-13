import 'package:flutter/material.dart';

/// 얼굴 화면용 Back 버튼 (공통)
class FaceBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const FaceBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 55,
      left: 55,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.arrow_back_ios, color: Colors.blue, size: 21),
            SizedBox(width: 8),
            Text(
              'back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
