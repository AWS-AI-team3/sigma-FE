import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class ControlButtons extends StatelessWidget {
  final bool isTrackingMode;
  final bool isCameraEnabled;
  final bool isMicEnabled;
  final VoidCallback onTrackingToggle;
  final VoidCallback onCameraToggle;
  final VoidCallback onMicToggle;

  const ControlButtons({
    super.key,
    required this.isTrackingMode,
    required this.isCameraEnabled,
    required this.isMicEnabled,
    required this.onTrackingToggle,
    required this.onCameraToggle,
    required this.onMicToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.play_circle,
          isActive: isTrackingMode,
          onTap: onTrackingToggle,
          tooltip: '트래킹 시작/중지',
        ),
        _buildControlButton(
          icon: Icons.videocam,
          isActive: (isTrackingMode && isCameraEnabled),
          color: (isTrackingMode && isCameraEnabled) 
              ? AppTheme.cameraGreen 
              : AppTheme.iconGray,
          onTap: onCameraToggle,
          tooltip: '카메라 켜기/끄기',
        ),
        _buildControlButton(
          icon: Icons.mic,
          isActive: isMicEnabled,
          color: isMicEnabled ? AppTheme.micRed : AppTheme.iconGray,
          onTap: onMicToggle,
          tooltip: '마이크 켜기/끄기',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    Color? color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.separatorGray,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: color ?? (isActive ? AppTheme.sigmaLightBlue : AppTheme.iconGray),
          ),
        ),
      ),
    );
  }
}