import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../widgets/floating_sidebar.dart';
import '../widgets/gesture_camera_overlay.dart';
import '../widgets/voice_subtitle_overlay.dart';
import '../services/voice_recognition_service.dart';
import '../services/audio_recording_service.dart';
import '../services/bookmark_service.dart';

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

  // Sidebar key to access hover methods
  final GlobalKey<FloatingSidebarState> _sidebarKey = GlobalKey<FloatingSidebarState>();

  // Voice recognition
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final AudioRecordingService _audioService = AudioRecordingService();
  String _currentSubtitle = '';
  bool _isVoiceRecording = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _initializeWebView();
    _initializeVoiceRecognition();
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
    // Convert screen coordinates to JavaScript click
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

            // Gesture Camera Overlay
            if (_isGestureEnabled)
              GestureCameraOverlay(
                onGestureClick: _handleGestureClick,
                onGestureDrag: _handleGestureDrag,
                onGestureSwipe: _handleGestureSwipe,
                onVoiceRecording: _handleVoiceRecording,
              ),

            // Voice Subtitle Overlay
            if (_isGestureEnabled)
              VoiceSubtitleOverlay(
                subtitle: _currentSubtitle,
                isRecording: _isVoiceRecording,
              ),

            // Hover detection area (left edge of screen, always present)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: MouseRegion(
                onEnter: (_) {
                  print('🖱️ Hover area ENTER');
                  _sidebarKey.currentState?.onHoverEnter();
                },
                onExit: (_) {
                  print('🖱️ Hover area EXIT');
                  _sidebarKey.currentState?.onHoverExit();
                },
                child: Container(
                  width: 100, // 100px wide hover detection strip
                  color: Colors.transparent,
                ),
              ),
            ),

            // Floating Sidebar (left-side overlay)
            Positioned(
              left: 0,
              top: 0,
              child: FloatingSidebar(
                key: _sidebarKey,
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
              ),
            ),

            // Cursor layer (topmost - above everything)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
