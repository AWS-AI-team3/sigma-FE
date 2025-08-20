import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'auth_storage_service.dart';

class PythonService {
  static Process? _handTrackingProcess;
  static bool _isTracking = false;
  static int? _pythonProcessId;
  static StreamController<Uint8List> _cameraStreamController = StreamController<Uint8List>.broadcast();
  static StreamController<String> _gestureStreamController = StreamController<String>.broadcast();
  static StreamController<Map<String, dynamic>> _transcriptStreamController = StreamController<Map<String, dynamic>>.broadcast();
  static StreamController<Map<String, dynamic>> _commandStreamController = StreamController<Map<String, dynamic>>.broadcast();

  /// Start hand tracking using Python overlay
  static Future<bool> startHandTracking({bool showSkeleton = false}) async {
    // 이미 실행 중인 경우 먼저 정리
    if (_isTracking) {
      print('Python process already running, cleaning up first...');
      await cleanup();
      // 약간의 대기 시간으로 완전한 정리를 보장
      await Future.delayed(const Duration(milliseconds: 500));
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

      // Get access token for motion settings
      final accessToken = await AuthStorageService.getValidAccessToken();
      
      // Build command arguments
      final args = [
        'run', 'python', '-u', pythonScriptPath, 
        '--show-skeleton', showSkeleton.toString()
      ];
      
      // Add access token if available
      if (accessToken != null) {
        args.addAll(['--access-token', accessToken]);
        print('Starting Python with access token for motion settings');
      } else {
        print('No access token available, using default motion mapping');
      }

      // Debug: Print command details
      print('Working directory: ${Directory.current.path}');
      print('Command: uv ${args.join(' ')}');
      print('Python script exists: ${await scriptFile.exists()}');
      
      // Try to find uv executable
      String uvExecutable = 'uv';
      if (Platform.isWindows) {
        // Try common uv installation paths on Windows
        final commonPaths = [
          'C:\\Users\\pjw03\\.local\\bin\\uv.exe',
          'uv.exe',
          'uv'
        ];
        
        for (final path in commonPaths) {
          try {
            final result = await Process.run(path, ['--version']);
            if (result.exitCode == 0) {
              uvExecutable = path;
              print('Found uv at: $uvExecutable');
              break;
            }
          } catch (e) {
            // Continue to next path
          }
        }
      }
      
      // Start Python process with hand tracking overlay using uv
      _handTrackingProcess = await Process.start(
        uvExecutable, 
        args,  // -u flag for unbuffered output
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.normal,
        environment: {
          'PYTHONUNBUFFERED': '1',  // Force unbuffered output
          'PYTHONIOENCODING': 'utf-8',  // Ensure UTF-8 encoding
        },
      );

      if (_handTrackingProcess != null) {
        _isTracking = true;
        _pythonProcessId = _handTrackingProcess!.pid;
        print('Hand tracking started successfully (PID: $_pythonProcessId)');
        
        // Process exit handler for debugging
        _handTrackingProcess!.exitCode.then((exitCode) {
          print('Python process exited with code: $exitCode');
          _isTracking = false;
        });
        
        // Listen to process output and parse camera frames and gestures
        _handTrackingProcess!.stdout.listen((data) {
          try {
            // Try to decode as UTF-8, skip if it fails
            final decoded = utf8.decode(data);
            final lines = decoded.split('\n');
            
            // Log only important non-empty lines (filter out routine messages)
            for (final line in lines) {
              if (line.trim().isNotEmpty && 
                  !line.contains('camera_frame') && 
                  !line.contains('Camera') &&
                  !line.contains('WebSocket Status') &&
                  !line.contains('frame') &&
                  !line.contains('Received stdin') &&
                  !line.contains('WebSocket connected') &&
                  line.trim().length < 200) {  // Skip very long lines
                print('Python: $line');
              }
            }
            
            for (final line in lines) {
              try {
                // Skip empty lines or lines with invalid characters
                if (line.trim().isEmpty || line.contains('\uFFFD')) {
                  continue;
                }
                
                // Additional check for valid JSON structure
                final trimmedLine = line.trim();
                if (!trimmedLine.startsWith('{') || !trimmedLine.endsWith('}')) {
                  // Log invalid JSON lines that contain "transcript"
                  if (trimmedLine.contains('transcript')) {
                    print('Invalid JSON line with transcript: $trimmedLine');
                  }
                  continue;
                }
                
                // Log all transcript-related lines before parsing
                if (trimmedLine.contains('transcript')) {
                  print('Transcript JSON line: $trimmedLine');
                }
                
                final jsonData = json.decode(trimmedLine);
                // Only log important JSON types to reduce noise
                if (jsonData['type'] != 'camera_frame' && 
                    jsonData['type'] != 'gesture' &&
                    !jsonData['type'].toString().contains('hold')) {
                  print('JSON parsed type: ${jsonData['type']}');
                }
                if (jsonData['type'] == 'camera_frame') {
                  // Decode base64 image data
                  final imageData = base64.decode(jsonData['data']);
                  _cameraStreamController.add(imageData);
                } else if (jsonData['type'] == 'gesture') {
                  // Send gesture data to gesture stream
                  _gestureStreamController.add(jsonData['gesture_type']);
                } else if (jsonData['type'] == 'transcript') {
                  // Send transcript data to transcript stream
                  final transcriptData = {
                    'text': jsonData['text'],
                    'is_partial': jsonData['is_partial'] ?? false,
                  };
                  print('Python transcript parsed: ${jsonData['text']}, is_partial: ${jsonData['is_partial']}');
                  _transcriptStreamController.add(transcriptData);
                } else if (jsonData['type'] == 'command_response' || 
                          jsonData['type'] == 'command_request' ||
                          jsonData['type'] == 'command_execution' ||
                          jsonData['type'] == 'transcript_cleared') {
                  // Send command-related data to command stream
                  _commandStreamController.add(jsonData);
                }
              } catch (e) {
                // If not JSON, treat as regular output (but filter out binary data)
                final trimmedLine = line.trim();
                if (trimmedLine.isNotEmpty && line.length < 1000 && !line.contains('\x00')) {
                  print('Python output: $trimmedLine');
                }
              }
            }
          } catch (e) {
            // Skip malformed UTF-8 data
            return;
          }
        });

        _handTrackingProcess!.stderr.listen((data) {
          try {
            final decoded = utf8.decode(data);
            // Check if transcript data is coming through stderr
            if (decoded.contains('transcript')) {
              print('Python stderr (transcript): $decoded');
            } else {
              print('Python error: $decoded');
            }
          } catch (e) {
            print('Error decode error: $e');
          }
        });

        return true;
      }
    } catch (e, stackTrace) {
      print('Error starting hand tracking: $e');
      print('Stack trace: $stackTrace');
      
      // Additional error information
      if (e is ProcessException) {
        print('ProcessException details:');
        print('  executable: ${e.executable}');
        print('  arguments: ${e.arguments}');
        print('  errorCode: ${e.errorCode}');
        print('  message: ${e.message}');
      }
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
    
    // Close and recreate stream controllers for fresh start
    try {
      if (!_cameraStreamController.isClosed) {
        await _cameraStreamController.close();
      }
      if (!_gestureStreamController.isClosed) {
        await _gestureStreamController.close();
      }
      if (!_transcriptStreamController.isClosed) {
        await _transcriptStreamController.close();
      }
      if (!_commandStreamController.isClosed) {
        await _commandStreamController.close();
      }
    } catch (e) {
      print('Error closing stream controllers: $e');
    }
    
    // Recreate stream controllers for fresh start
    _cameraStreamController = StreamController<Uint8List>.broadcast();
    _gestureStreamController = StreamController<String>.broadcast();
    _transcriptStreamController = StreamController<Map<String, dynamic>>.broadcast();
    _commandStreamController = StreamController<Map<String, dynamic>>.broadcast();
    
    print('Python service cleanup completed and stream controllers recreated');
  }

  /// Check if hand tracking is currently active
  static bool get isTracking => _isTracking;

  /// Get camera stream from MediaPipe
  static Stream<Uint8List> get cameraStream => _cameraStreamController.stream;
  
  /// Get gesture stream from MediaPipe
  static Stream<String> get gestureStream => _gestureStreamController.stream;
  
  /// Get transcript stream from Python audio recording
  static Stream<Map<String, dynamic>> get transcriptStream => _transcriptStreamController.stream;
  
  /// Get command stream from Python command processing
  static Stream<Map<String, dynamic>> get commandStream => _commandStreamController.stream;
  
  /// Send command to Python process
  static void sendCommand(String command, [String? text]) {
    if (_handTrackingProcess != null && _isTracking) {
      try {
        final commandData = {
          'type': command,
          if (text != null) 'text': text,
        };
        final jsonCommand = json.encode(commandData);
        _handTrackingProcess!.stdin.writeln(jsonCommand);
        print('Sent command to Python: $jsonCommand');
      } catch (e) {
        print('Error sending command to Python: $e');
      }
    } else {
      print('Cannot send command: Python process not running');
    }
  }

  /// Update skeleton display setting
  static void updateSkeletonDisplay(bool showSkeleton) {
    if (_handTrackingProcess != null && _isTracking) {
      try {
        final commandData = {
          'type': 'update_skeleton_display',
          'show_skeleton': showSkeleton,
        };
        final jsonCommand = json.encode(commandData);
        _handTrackingProcess!.stdin.writeln(jsonCommand);
        print('Updated skeleton display: $showSkeleton');
      } catch (e) {
        print('Error updating skeleton display: $e');
      }
    } else {
      print('Cannot update skeleton display: Python process not running');
    }
  }

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
      await Process.start(
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