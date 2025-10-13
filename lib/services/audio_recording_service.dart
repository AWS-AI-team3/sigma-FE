import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Callback for audio data chunks
  Function(String base64Audio)? onAudioData;

  // Start recording
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('🎤 Already recording');
      return true;
    }

    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        print('❌ Microphone permission denied');
        return false;
      }

      print('🎤 Starting audio recording...');

      // Configure recording
      // iOS supports PCM16 format directly
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000, // 16kHz as required by AWS Transcribe
        numChannels: 1, // Mono
        bitRate: 256000,
      );

      // Start recording with stream
      final stream = await _recorder.startStream(config);

      _audioStreamSubscription = stream.listen(
        (audioChunk) {
          _handleAudioChunk(audioChunk);
        },
        onError: (error) {
          print('❌ Audio stream error: $error');
          _isRecording = false;
        },
        onDone: () {
          print('🛑 Audio stream done');
          _isRecording = false;
        },
      );

      _isRecording = true;
      print('✅ Recording started (16kHz, 1 channel, PCM16)');
      return true;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  // Stop recording
  Future<bool> stopRecording() async {
    if (!_isRecording) {
      print('🎤 Not recording');
      return true;
    }

    try {
      print('🛑 Stopping audio recording...');

      // Cancel stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Stop recorder
      await _recorder.stop();

      _isRecording = false;
      print('✅ Recording stopped');
      return true;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return false;
    }
  }

  // Handle audio chunk
  void _handleAudioChunk(Uint8List audioChunk) {
    if (onAudioData != null && audioChunk.isNotEmpty) {
      // Convert to Base64
      final base64Audio = base64Encode(audioChunk);

      // Send to callback
      onAudioData!(base64Audio);
    }
  }

  // Dispose
  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
  }
}
