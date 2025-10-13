import 'package:flutter/material.dart';

class WebSocketStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isRecording;
  final VoidCallback? onReconnect;

  const WebSocketStatusIndicator({
    super.key,
    required this.isConnected,
    required this.isRecording,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: GestureDetector(
        onTap: !isConnected ? onReconnect : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Connection status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Status text
              Text(
                isConnected ? 'WebSocket 연결됨' : 'WebSocket 연결 끊김',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRecording) ...[
                const SizedBox(width: 8),
                const Icon(Icons.mic, color: Colors.red, size: 16),
              ],
              if (!isConnected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.refresh, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
