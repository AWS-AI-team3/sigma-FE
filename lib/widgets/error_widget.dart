import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryText = '다시 시도',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: _getErrorColor(),
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getErrorColor(),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.camera:
        return Icons.camera_alt_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.auth:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.camera:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return '네트워크 연결 오류';
      case ErrorType.auth:
        return '인증 오류';
      case ErrorType.validation:
        return '입력 오류';
      case ErrorType.camera:
        return '카메라 오류';
      case ErrorType.unknown:
        return '오류 발생';
    }
  }
}