import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class VoiceRecognitionService {
  static const String _wsUrl =
      'wss://4tj4nr6tca.execute-api.ap-northeast-2.amazonaws.com/dev/';

  WebSocketChannel? _channel;
  final StreamController<TranscriptResult> _transcriptController =
      StreamController<TranscriptResult>.broadcast();

  bool _isConnected = false;
  bool _isRecording = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Transcript stream for UI consumption
  Stream<TranscriptResult> get transcriptStream => _transcriptController.stream;

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;

  // Connect to WebSocket
  Future<bool> connect() async {
    if (_isConnected) {
      print('🎤 Already connected to WebSocket');
      return true;
    }

    try {
      print('🎤 Connecting to WebSocket: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
          _reconnectAttempts = 0; // Reset on successful message
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      print('✅ WebSocket connected');
      return true;
    } catch (e) {
      print('❌ Failed to connect to WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }

  // Disconnect from WebSocket
  void disconnect() {
    if (_channel != null) {
      print('🔌 Disconnecting WebSocket');
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _isRecording = false;
    }
  }

  // Start transcription
  Future<bool> startTranscription() async {
    if (!_isConnected) {
      print('❌ Not connected to WebSocket');
      return false;
    }

    if (_isRecording) {
      print('🎤 Already recording');
      return true;
    }

    try {
      final message = {
        'action': 'transcribe_streaming',
        'type': 'start_transcribe',
      };

      _channel!.sink.add(json.encode(message));
      _isRecording = true;
      print('🎤 Started transcription');
      return true;
    } catch (e) {
      print('❌ Failed to start transcription: $e');
      return false;
    }
  }

  // Send audio data
  Future<bool> sendAudioData(String base64Audio) async {
    if (!_isConnected || !_isRecording) {
      return false;
    }

    try {
      final message = {
        'action': 'transcribe_streaming',
        'type': 'send_audio',
        'data': base64Audio,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _channel!.sink.add(json.encode(message));
      return true;
    } catch (e) {
      print('❌ Failed to send audio data: $e');
      return false;
    }
  }

  // Stop transcription
  Future<bool> stopTranscription() async {
    if (!_isConnected) {
      return false;
    }

    if (!_isRecording) {
      print('🎤 Not recording');
      return true;
    }

    try {
      final message = {
        'action': 'transcribe_streaming',
        'type': 'stop_transcribe',
      };

      _channel!.sink.add(json.encode(message));
      _isRecording = false;
      print('🛑 Stopped transcription');
      return true;
    } catch (e) {
      print('❌ Failed to stop transcription: $e');
      return false;
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      print('📩 Received message: $data');

      if (data['type'] == 'transcript') {
        final transcript = TranscriptResult(
          text: data['text'] ?? '',
          isPartial: data['is_partial'] ?? false,
        );

        _transcriptController.add(transcript);
        print(
          '📝 Transcript: ${transcript.text} (partial: ${transcript.isPartial})',
        );
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = Duration(
      seconds: 2 * _reconnectAttempts,
    ); // Exponential backoff
    print(
      '🔄 Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () async {
      print('🔄 Attempting to reconnect...');
      await connect();
    });
  }

  // Manual reconnect
  Future<bool> reconnect() async {
    _reconnectAttempts = 0;
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    return await connect();
  }

  // Dispose
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _transcriptController.close();
  }
}

// Transcript result model
class TranscriptResult {
  final String text;
  final bool isPartial;

  TranscriptResult({required this.text, required this.isPartial});
}
