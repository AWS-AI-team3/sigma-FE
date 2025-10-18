import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../widgets/floating_sidebar.dart';
import '../widgets/gesture_camera_overlay.dart';
import '../widgets/voice_recording_modal.dart';
import '../services/voice_recognition_service.dart';
import '../services/audio_recording_service.dart';
import '../services/bookmark_service.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/profile_modal.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _webViewController;
  String _currentUrl = 'https://www.google.com';
  bool _isGestureEnabled = false;

  List<Bookmark> _bookmarks = [];

  // Sidebar show callback
  VoidCallback? _showSidebarCallback;

  // Voice recognition
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final AudioRecordingService _audioService = AudioRecordingService();
  String _currentSubtitle = '';
  bool _isVoiceRecording = false;

  // Profile modal
  bool _showProfileModal = false;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadUserInfo();
    _initializeWebView();
    _initializeVoiceRecognition();
  }

  Future<void> _loadUserInfo() async {
    final info = await UserService.getUserInfo();
    if (mounted && info != null && info['sucess'] == true && info['data'] != null) {
      setState(() {
        _userInfo = info['data'];
      });
    }
  }

  void _showProfile() {
    setState(() {
      _showProfileModal = true;
    });
  }

  Future<void> _handleLogout() async {
    // Close modal first
    setState(() {
      _showProfileModal = false;
    });

    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call logout API
    final authService = GoogleAuthService();
    final success = await authService.signOut();

    if (!mounted) return;

    // Close loading indicator
    Navigator.of(context).pop();

    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    // Show result message
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 되었습니다')),
      );
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
    });
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceRecognition() async {
    // Connect to WebSocket
    final connected = await _voiceService.connect();
    if (connected) {
      print('✅ Voice recognition connected');

      // Listen to transcript stream
      _voiceService.transcriptStream.listen((transcript) {
        setState(() {
          _currentSubtitle = transcript.text;
        });
        print(
          '📝 Transcript: ${transcript.text} (partial: ${transcript.isPartial})',
        );

        // 최종 transcript일 때만 명령 처리
        if (!transcript.isPartial && transcript.text.isNotEmpty) {
          _handleVoiceCommand(transcript.text);
        }
      });

      // Set audio data callback
      _audioService.onAudioData = (base64Audio) {
        _voiceService.sendAudioData(base64Audio);
      };
    } else {
      print('❌ Failed to connect voice recognition');
    }
  }

  void _initializeWebView() {
    // Configure WKWebView for iOS to allow inline playback
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            // Prevent automatic fullscreen
            _preventAutoFullscreen();
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _preventAutoFullscreen() {
    // Inject JavaScript to force inline playback and block fullscreen
    _webViewController.runJavaScript('''
      (function() {
        // Force playsinline on all video elements
        function forceInlinePlayback() {
          document.querySelectorAll('video').forEach(function(video) {
            video.setAttribute('playsinline', '');
            video.setAttribute('webkit-playsinline', '');
            video.removeAttribute('fullscreen');
          });
        }

        // Run immediately and on DOM changes
        forceInlinePlayback();
        const observer = new MutationObserver(forceInlinePlayback);
        observer.observe(document.body, { childList: true, subtree: true });

        // Override fullscreen methods
        Element.prototype.requestFullscreen = function() {
          console.log('Fullscreen blocked');
          return Promise.reject(new Error('Fullscreen blocked'));
        };

        if (Element.prototype.webkitRequestFullscreen) {
          Element.prototype.webkitRequestFullscreen = function() {
            console.log('Webkit fullscreen blocked');
            return Promise.reject(new Error('Fullscreen blocked'));
          };
        }

        if (Element.prototype.webkitEnterFullscreen) {
          Element.prototype.webkitEnterFullscreen = function() {
            console.log('iOS fullscreen blocked');
          };
        }

        // Also override webkitEnterFullScreen (capital S)
        if (Element.prototype.webkitEnterFullScreen) {
          Element.prototype.webkitEnterFullScreen = function() {
            console.log('iOS fullScreen blocked');
          };
        }
      })();
    ''');
  }

  void _navigateToUrl(String url) {
    setState(() {
      _currentUrl = url;
    });
    _webViewController.loadRequest(Uri.parse(url));
  }

  void _handleGestureClick(Offset position) {
    print('🎯 Gesture click at: $position');

    // Check if click is on sidebar area (left edge, approximately 100px)
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 836;
    final sidebarWidth = 100 * scale;

    // If modal is open, check modal area first (center of screen)
    if (_showProfileModal) {
      final modalWidth = 285 * scale;
      final modalHeight = 419 * scale;
      final screenHeight = MediaQuery.of(context).size.height;

      final modalLeft = (screenWidth - modalWidth) / 2;
      final modalRight = modalLeft + modalWidth;
      final modalTop = (screenHeight - modalHeight) / 2;
      final modalBottom = modalTop + modalHeight;

      if (position.dx >= modalLeft && position.dx <= modalRight &&
          position.dy >= modalTop && position.dy <= modalBottom) {
        print('🎯 Click inside modal area - checking elements');

        // Check close button (top-left)
        final closeButtonLeft = modalLeft + 10 * scale;
        final closeButtonTop = modalTop + 10 * scale;
        final closeButtonSize = 12 * scale;

        if (position.dx >= closeButtonLeft &&
            position.dx <= closeButtonLeft + closeButtonSize &&
            position.dy >= closeButtonTop &&
            position.dy <= closeButtonTop + closeButtonSize) {
          print('✅ Clicked close button');
          setState(() {
            _showProfileModal = false;
          });
          return;
        }

        // Check logout button (near bottom)
        final logoutTop = modalTop + 361 * scale;
        final logoutHeight = 12 * scale;

        if (position.dy >= logoutTop && position.dy <= logoutTop + logoutHeight) {
          print('✅ Clicked logout button');
          _handleLogout();
          return;
        }

        // Click on modal but not on interactive elements - do nothing
        print('🎯 Click on modal background - ignoring');
        return;
      } else {
        // Click outside modal - close it
        print('✅ Click outside modal - closing');
        setState(() {
          _showProfileModal = false;
        });
        return;
      }
    }

    // Check if click is on sidebar area
    if (position.dx <= sidebarWidth) {
      print('🎯 Click on sidebar area at: dx=${position.dx}, dy=${position.dy}');

      // Sidebar has complex layout - it's vertically centered
      // Calculate the same way as floating_sidebar.dart does
      final screenHeight = MediaQuery.of(context).size.height;

      // Main panel height calculation (from floating_sidebar.dart)
      final baseHeight = 52.0 + 50.0 + 16.0 + 56.0 + 2.0; // 176
      final bookmarkHeight = _bookmarks.length * 50.0;
      final mainPanelHeight = (baseHeight + bookmarkHeight) * scale;

      // Main panel is vertically centered
      final mainPanelTop = (screenHeight - mainPanelHeight) / 2;

      // Sidebar has left padding 13 * scale + container padding 10 * scale
      final sidebarLeft = (13 + 10) * scale;
      final buttonSize = 42 * scale;

      print('   Sidebar left: $sidebarLeft, Main panel top: $mainPanelTop');
      print('   Button size: $buttonSize');

      // Profile button (first in main panel, with 10px top padding)
      final profileTop = mainPanelTop + 10 * scale;
      print('   Profile button: top=$profileTop, bottom=${profileTop + buttonSize}');

      if (position.dx >= sidebarLeft &&
          position.dx <= sidebarLeft + buttonSize &&
          position.dy >= profileTop &&
          position.dy <= profileTop + buttonSize) {
        print('✅ Clicked profile button');
        _showProfile();
        return;
      }

      // Gesture toggle button (8px spacing after profile)
      final gestureToggleTop = profileTop + buttonSize + 8 * scale;
      print('   Gesture toggle: top=$gestureToggleTop, bottom=${gestureToggleTop + buttonSize}');

      if (position.dx >= sidebarLeft &&
          position.dx <= sidebarLeft + buttonSize &&
          position.dy >= gestureToggleTop &&
          position.dy <= gestureToggleTop + buttonSize) {
        print('✅ Clicked gesture toggle button');
        setState(() {
          _isGestureEnabled = !_isGestureEnabled;
        });
        return;
      }

      print('🎯 Click on sidebar but not on profile or gesture toggle');
      return;
    }

    // Otherwise, send click to WebView
    print('🎯 Sending click to WebView');
    _webViewController.runJavaScript('''
      var element = document.elementFromPoint(${position.dx}, ${position.dy});
      if (element) {
        element.click();
      }
    ''');
  }

  void _handleGestureDrag(String action, Offset position) {
    // action: 'start', 'move', 'end'
    _webViewController.runJavaScript('''
      var element = document.elementFromPoint(${position.dx}, ${position.dy});
      if (element) {
        var event;
        if ('$action' === 'start') {
          event = new MouseEvent('mousedown', {
            bubbles: true,
            cancelable: true,
            view: window,
            clientX: ${position.dx},
            clientY: ${position.dy}
          });
        } else if ('$action' === 'move') {
          event = new MouseEvent('mousemove', {
            bubbles: true,
            cancelable: true,
            view: window,
            clientX: ${position.dx},
            clientY: ${position.dy}
          });
        } else if ('$action' === 'end') {
          event = new MouseEvent('mouseup', {
            bubbles: true,
            cancelable: true,
            view: window,
            clientX: ${position.dx},
            clientY: ${position.dy}
          });
        }
        if (event) {
          element.dispatchEvent(event);
        }
      }
    ''');
  }

  void _handleGestureSwipe(String direction, {int? scrollAmount}) {
    switch (direction) {
      case 'left':
        _webViewController.goForward();
        break;
      case 'right':
        _webViewController.goBack();
        break;
      case 'up':
        // 스크롤 양이 있으면 사용, 없으면 기본값
        final amount = scrollAmount ?? 50;
        _webViewController.scrollBy(0, -amount);
        break;
      case 'down':
        final amount = scrollAmount ?? 50;
        _webViewController.scrollBy(0, amount);
        break;
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    print('🎙️ Voice command: $command');

    // 1. 즐겨찾기 찾기
    final bookmark = await BookmarkService.findBookmarkByVoice(command);
    if (bookmark != null) {
      print('✅ Found bookmark: ${bookmark.name} -> ${bookmark.url}');
      _navigateToUrl(bookmark.url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${bookmark.name} 페이지로 이동'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 2. 특수 명령어 처리
    if (command.contains('뒤로') || command.contains('back')) {
      _webViewController.goBack();
      print('⬅️ Navigate back');
      return;
    } else if (command.contains('앞으로') || command.contains('forward')) {
      _webViewController.goForward();
      print('➡️ Navigate forward');
      return;
    } else if (command.contains('새로고침') ||
        command.contains('refresh') ||
        command.contains('reload')) {
      _webViewController.reload();
      print('🔄 Reload page');
      return;
    }

    // 3. AI 명령어 생성 (즐겨찾기 매칭 실패시)
    print('🤖 No bookmark match, trying AI command generation...');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI로 명령어 변환 중...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final url = await _voiceService.generateCommand(command);

    if (url != null && url.isNotEmpty) {
      print('✅ AI generated URL: $url');

      // URL 유효성 검사
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _navigateToUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI 명령: $url 로 이동'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ Invalid URL from AI: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('유효하지 않은 URL입니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      print('❌ AI command generation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('명령을 이해할 수 없습니다: $command'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleVoiceRecording(bool isRecording) async {
    print('🎤 Voice recording: $isRecording');

    if (isRecording && !_isVoiceRecording) {
      // Start recording
      setState(() {
        _isVoiceRecording = true;
        _currentSubtitle = '';
      });

      // Start WebSocket transcription and audio recording asynchronously
      // Don't await to avoid blocking gesture detection stream
      _voiceService.startTranscription().then((_) {
        print('✅ WebSocket transcription started');
      }).catchError((e) {
        print('❌ Failed to start transcription: $e');
      });
      
      _audioService.startRecording().then((success) {
        if (success) {
          print('✅ Audio recording started');
        } else {
          print('❌ Failed to start audio recording');
        }
      }).catchError((e) {
        print('❌ Audio recording error: $e');
      });
    } else if (!isRecording && _isVoiceRecording) {
      // 녹음 중지 전에 현재 자막으로 명령 실행
      final finalCommand = _currentSubtitle.trim();

      // Stop recording immediately (UI update)
      setState(() {
        _isVoiceRecording = false;
      });

      // Stop audio recording and transcription asynchronously
      _audioService.stopRecording().then((_) {
        print('🛑 Audio recording stopped');
      });
      
      _voiceService.stopTranscription().then((_) {
        print('🛑 WebSocket transcription stopped');
      });

      // 최종 명령 처리
      if (finalCommand.isNotEmpty) {
        print('🎯 Processing final command: $finalCommand');
        await _handleVoiceCommand(finalCommand);
      }

      // Clear subtitle after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentSubtitle = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          // Two-finger double tap to show sidebar
          onDoubleTapDown: (details) {
            if (details.kind != null) {
              // Trigger show sidebar
              _showSidebarCallback?.call();
            }
          },
          child: Stack(
            children: [
              // Full-screen WebView
              WebViewWidget(controller: _webViewController),

            // Floating Sidebar (left-side overlay)
            Positioned(
              left: 0,
              top: 0,
              child: FloatingSidebar(
                bookmarks: _bookmarks,
                currentUrl: _currentUrl,
                onBookmarkTap: _navigateToUrl,
                isGestureEnabled: _isGestureEnabled,
                onGestureToggle: (value) {
                  setState(() {
                    _isGestureEnabled = value;
                  });
                },
                onBookmarksChanged: _loadBookmarks,
                isWebSocketConnected: _voiceService.isConnected,
                isVoiceRecording: _isVoiceRecording,
                onWebSocketReconnect: () async {
                  print('🔄 Manual reconnect requested');
                  await _voiceService.reconnect();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WebSocket 재연결 성공')),
                  );
                },
                onRegisterShowCallback: (callback) {
                  _showSidebarCallback = callback;
                },
                onProfileTap: _showProfile,
              ),
            ),

            // Profile Modal (below gesture overlay so cursor can interact with sidebar)
            if (_showProfileModal)
              ProfileModal(
                userInfo: _userInfo,
                onLogout: _handleLogout,
                onClose: () {
                  setState(() {
                    _showProfileModal = false;
                  });
                },
              ),

            // Voice Recording Modal (centered at bottom)
            if (_isGestureEnabled && _isVoiceRecording)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: VoiceRecordingModal(
                  transcription: _currentSubtitle.isNotEmpty ? _currentSubtitle : null,
                ),
              ),

            // Gesture Camera Overlay (topmost - cursor must be above everything)
            if (_isGestureEnabled)
              GestureCameraOverlay(
                onGestureClick: _handleGestureClick,
                onGestureDrag: _handleGestureDrag,
                onGestureSwipe: _handleGestureSwipe,
                onVoiceRecording: _handleVoiceRecording,
                onLeftEdgeHover: () {
                  // Show sidebar when cursor hovers on left edge
                  _showSidebarCallback?.call();
                },
              ),
          ],
        ),
        ),
      ),
    );
  }
}
