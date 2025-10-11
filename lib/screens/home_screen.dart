import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../widgets/sidebar.dart';
import '../widgets/gesture_camera_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _webViewController;
  String _currentUrl = 'https://www.google.com';
  bool _isGestureEnabled = false;

  final List<Map<String, String>> _bookmarks = [
    {'name': 'Google', 'url': 'https://www.google.com'},
    {'name': 'YouTube', 'url': 'https://www.youtube.com'},
    {'name': 'GitHub', 'url': 'https://github.com'},
    {'name': 'Flutter', 'url': 'https://flutter.dev'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            Sidebar(
              bookmarks: _bookmarks,
              currentUrl: _currentUrl,
              onBookmarkTap: _navigateToUrl,
              isGestureEnabled: _isGestureEnabled,
              onGestureToggle: (value) {
                setState(() {
                  _isGestureEnabled = value;
                });
              },
            ),

            // WebView with Gesture Overlay
            Expanded(
              child: Stack(
                children: [
                  // WebView
                  WebViewWidget(controller: _webViewController),

                  // Gesture Camera Overlay
                  if (_isGestureEnabled)
                    GestureCameraOverlay(
                      onGestureClick: _handleGestureClick,
                      onGestureSwipe: _handleGestureSwipe,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
