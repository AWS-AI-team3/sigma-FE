import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class VoiceRecognitionService {
  static const String _baseUrl = 'https://www.3-sigma-server.com';
  static const String _wsBaseUrl =
      'wss://4tj4nr6tca.execute-api.ap-northeast-2.amazonaws.com/dev';

  WebSocketChannel? _channel;
  final StreamController<TranscriptResult> _transcriptController =
      StreamController<TranscriptResult>.broadcast();

  bool _isConnected = false;
  bool _isRecording = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Command response handling
  Completer<String?>? _commandCompleter;

  // Transcript stream for UI consumption
  Stream<TranscriptResult> get transcriptStream => _transcriptController.stream;

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;

  // Get gateway token from backend
  Future<String?> _getGatewayToken() async {
    try {
      print('🔑 Requesting gateway token from backend...');

      // Get user's access token
      final accessToken = await AuthStorageService.getValidAccessToken();
      if (accessToken == null) {
        print('❌ No valid access token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/gateway/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['data']?['gatewayToken'];

        if (token != null) {
          print('✅ Gateway token received');
          return token;
        } else {
          print('❌ Gateway token not found in response');
          return null;
        }
      } else {
        print('❌ Failed to get gateway token: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting gateway token: $e');
      return null;
    }
  }

  // Connect to WebSocket
  Future<bool> connect() async {
    if (_isConnected) {
      print('🎤 Already connected to WebSocket');
      return true;
    }

    try {
      // Step 1: Get gateway token
      final token = await _getGatewayToken();
      if (token == null) {
        print('❌ Cannot connect without gateway token');
        return false;
      }

      // Step 2: Connect to WebSocket with token
      final wsUrl = '$_wsBaseUrl?gatewayToken=$token';
      print(
        '🎤 Connecting to WebSocket with token: $_wsBaseUrl?gatewayToken=***',
      );

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

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

  // Start transcription (using optimized version)
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
        'action': 'transcribe_optimized',
        'type': 'start_transcribe',
      };

      _channel!.sink.add(json.encode(message));
      _isRecording = true;
      print('🎤 Started transcription (optimized)');
      return true;
    } catch (e) {
      print('❌ Failed to start transcription: $e');
      return false;
    }
  }

  // Send audio data (using optimized version)
  Future<bool> sendAudioData(String base64Audio) async {
    if (!_isConnected || !_isRecording) {
      return false;
    }

    try {
      final message = {
        'action': 'transcribe_optimized',
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

  // Stop transcription (using optimized version)
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
        'action': 'transcribe_optimized',
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

  // Generate command using AI (v2)
  Future<String?> generateCommand(String voiceInput) async {
    if (!_isConnected) {
      print('❌ Not connected to WebSocket');
      return null;
    }

    try {
      print('🤖 Requesting AI command generation for: "$voiceInput"');

      // Start timing
      final startTime = DateTime.now();

      // Create new completer for this request
      _commandCompleter = Completer<String?>();

      final message = {
        'action': 'generate_command_v2',
        'type': 'request_command',
        'request': voiceInput,
      };

      _channel!.sink.add(json.encode(message));

      // Wait for response with timeout
      final result = await _commandCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ AI command generation timeout');
          return null;
        },
      );

      // Calculate response time
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print(
        '⏱️ AI response time: ${duration.inMilliseconds}ms (${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );

      return result;
    } catch (e) {
      print('❌ Failed to generate command: $e');
      return null;
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
      } else if (data['type'] == 'respond_command') {
        // Handle AI command response
        if (_commandCompleter != null && !_commandCompleter!.isCompleted) {
          if (data['success'] == true && data['command'] != null) {
            print('✅ AI generated command: ${data['command']}');
            _commandCompleter!.complete(data['command']);
          } else {
            print('❌ AI command generation failed: ${data['message']}');
            _commandCompleter!.complete(null);
          }
        }
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
