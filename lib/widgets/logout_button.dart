import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_ios,
            color: AppTheme.sigmaLightBlue,
            size: 16,
          ),
          const SizedBox(width: 4),
          Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              '로그아웃',
              style: TextStyle(
                fontFamily: 'AppleSDGothicNeo',
                color: AppTheme.sigmaLightBlue,
                fontSize: 20,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}