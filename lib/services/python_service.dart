import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class PythonService {
  static Process? _handTrackingProcess;
  static bool _isTracking = false;
  static int? _pythonProcessId;
  static final StreamController<Uint8List> _cameraStreamController = StreamController<Uint8List>.broadcast();
  static final StreamController<String> _gestureStreamController = StreamController<String>.broadcast();

  /// Start hand tracking using Python overlay
  static Future<bool> startHandTracking() async {
    if (_isTracking) {
      return true;
    }

    try {
      // Path to Python script - adjust based on your project structure
      final pythonScriptPath = Platform.isWindows 
        ? 'python\\hand_tracking_standalone.py'
        : 'python/hand_tracking_standalone.py';
      
      // Check if Python script exists
      final scriptFile = File(pythonScriptPath);
      if (!await scriptFile.exists()) {
        print('Python script not found at: $pythonScriptPath');
        return false;
      }

      // Start Python process with hand tracking overlay using uv
      _handTrackingProcess = await Process.start(
        'uv', 
        ['run', 'python', pythonScriptPath],
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.normal,
      );

      if (_handTrackingProcess != null) {
        _isTracking = true;
        _pythonProcessId = _handTrackingProcess!.pid;
        print('Hand tracking started successfully (PID: $_pythonProcessId)');
        
        // Listen to process output and parse camera frames and gestures
        _handTrackingProcess!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
          try {
            final jsonData = json.decode(line);
            if (jsonData['type'] == 'camera_frame') {
              // Decode base64 image data
              final imageData = base64.decode(jsonData['data']);
              _cameraStreamController.add(imageData);
            } else if (jsonData['type'] == 'gesture') {
              // Send gesture data to gesture stream
              _gestureStreamController.add(jsonData['gesture_type']);
            }
          } catch (e) {
            // If not JSON, treat as regular output
            print('Python output: $line');
          }
        });

        _handTrackingProcess!.stderr.listen((data) {
          try {
            final decoded = utf8.decode(data, allowMalformed: true);
            print('Python error: $decoded');
          } catch (e) {
            print('Error decode error: $e');
          }
        });

        return true;
      }
    } catch (e) {
      print('Error starting hand tracking: $e');
    }
    
    return false;
  }

  /// Stop hand tracking
  static Future<void> stopHandTracking() async {
    if (_handTrackingProcess != null) {
      print('Stopping hand tracking process (PID: $_pythonProcessId)...');
      
      // Try graceful shutdown first
      _handTrackingProcess!.kill();
      
      // Wait a bit for graceful shutdown
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Force kill if still running (Windows specific)
      if (_pythonProcessId != null && Platform.isWindows) {
        try {
          await Process.run('taskkill', ['/F', '/PID', '$_pythonProcessId'], runInShell: true);
          print('Force killed Python process PID: $_pythonProcessId');
        } catch (e) {
          print('Error force killing process: $e');
        }
      }
      
      _handTrackingProcess = null;
      _pythonProcessId = null;
      _isTracking = false;
      print('Hand tracking stopped');
    }
  }

  /// Clean up all processes (call this when app is closing)
  static Future<void> cleanup() async {
    print('Cleaning up Python processes...');
    await stopHandTracking();
    
    // Additional cleanup for any remaining Python processes
    if (Platform.isWindows) {
      try {
        // Kill any uv run python processes that might be hanging
        await Process.run('taskkill', ['/F', '/IM', 'python.exe', '/T'], runInShell: true);
        await Process.run('wmic', ['process', 'where', 'commandline like "%hand_tracking_standalone.py%"', 'delete'], runInShell: true);
        print('Force killed all Python processes');
      } catch (e) {
        print('Error in additional cleanup: $e');
      }
    }
    
    // Close the stream controllers
    if (!_cameraStreamController.isClosed) {
      await _cameraStreamController.close();
    }
    if (!_gestureStreamController.isClosed) {
      await _gestureStreamController.close();
    }
    
    print('Python service cleanup completed');
  }

  /// Check if hand tracking is currently active
  static bool get isTracking => _isTracking;

  /// Get camera stream from MediaPipe
  static Stream<Uint8List> get cameraStream => _cameraStreamController.stream;
  
  /// Get gesture stream from MediaPipe
  static Stream<String> get gestureStream => _gestureStreamController.stream;
  

  /// Start the main PyQt application
  static Future<bool> startPyQtApp() async {
    try {
      final pythonScriptPath = Platform.isWindows 
        ? 'python\\pyqt_main.py'
        : 'python/pyqt_main.py';
      
      final scriptFile = File(pythonScriptPath);
      if (!await scriptFile.exists()) {
        print('PyQt main script not found at: $pythonScriptPath');
        return false;
      }

      // Start PyQt main application using uv
      final process = await Process.start(
        'uv', 
        ['run', 'python', pythonScriptPath],
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.detached,
      );

      print('PyQt application started');
      return true;
    } catch (e) {
      print('Error starting PyQt application: $e');
      return false;
    }
  }
}