import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';
import '../services/user_service.dart';

class FloatingSidebar extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final String currentUrl;
  final Function(String) onBookmarkTap;
  final bool isGestureEnabled;
  final Function(bool) onGestureToggle;
  final VoidCallback onBookmarksChanged;
  final bool isWebSocketConnected;
  final bool isVoiceRecording;
  final VoidCallback onWebSocketReconnect;
  final Function(VoidCallback)? onRegisterShowCallback;
  final VoidCallback? onProfileTap;

  const FloatingSidebar({
    super.key,
    required this.bookmarks,
    required this.currentUrl,
    required this.onBookmarkTap,
    required this.isGestureEnabled,
    required this.onGestureToggle,
    required this.onBookmarksChanged,
    required this.isWebSocketConnected,
    required this.isVoiceRecording,
    required this.onWebSocketReconnect,
    this.onRegisterShowCallback,
    this.onProfileTap,
  });

  @override
  State<FloatingSidebar> createState() => FloatingSidebarState();
}

class FloatingSidebarState extends State<FloatingSidebar>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userInfo;
  bool _isDeleteMode = false; // 삭제 모드 상태
  Timer? _hideTimer; // 자동 숨김 타이머
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // 슬라이드 애니메이션 컨트롤러
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 왼쪽에서 오른쪽으로 슬라이드
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(-1.0, 0.0), // 화면 왼쪽 밖
          end: Offset.zero, // 원래 위치
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    // Register showSidebar callback to parent
    widget.onRegisterShowCallback?.call(showSidebar);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  // Public method to show sidebar (called from parent - for double tap gesture or left edge hover)
  void showSidebar() {
    print('🎯 showSidebar() called');
    _hideTimer?.cancel();
    _slideController.forward();

    // Start hide timer immediately after showing
    _hideTimer = Timer(const Duration(seconds: 5), () {
      print('⏱️ showSidebar Timer fired: mounted=$mounted');
      if (mounted) {
        print('✅ Hiding sidebar from showSidebar');
        _slideController.reverse(); // 사라지기
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final info = await UserService.getUserInfo();

    if (!mounted) return;

    if (info != null && info['sucess'] == true && info['data'] != null) {
      setState(() {
        _userInfo = info['data'];
      });
    } else {
      print(
        '⚠️ User info not available: ${info?['error']?['message'] ?? 'Unknown error'}',
      );
      print('📝 TODO: Server needs to implement /v1/user/info endpoint');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Figma frame: 836x584
    // iPad Air 11": 834x1194
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = screenWidth / 836;

    // Calculate dynamic height for main panel
    // Profile: top(10) + image(42) = 52
    // Gesture: spacing(8) + button(42) = 50
    // Divider: vertical padding(8+8) = 16
    // Add button: top(4) + button(42) + bottom(10) = 56
    // Each bookmark: vertical margin(4+4) + button(42) = 50
    // Add 2px buffer for rounding/padding
    final baseHeight = 52.0 + 50.0 + 16.0 + 56.0 + 2.0; // 176
    final bookmarkHeight = widget.bookmarks.length * 50.0;
    final mainPanelHeight = baseHeight + bookmarkHeight;

    // Gap between Rectangle 22 and Rectangle 13
    final gap = 5.0 * scale;
    final topBarHeight = 28.0 * scale;

    // Calculate top position to center Rectangle 13 vertically
    // Rectangle 13 center position
    final mainPanelCenterTop = (screenHeight - (mainPanelHeight * scale)) / 2;
    // Rectangle 22 position (above Rectangle 13)
    final topBarTop = mainPanelCenterTop - topBarHeight - gap;

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.only(left: 13 * scale, top: topBarTop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center align
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rectangle 22 - Top Bar (Bookmark + Mic icons)
            _buildTopBar(scale),

            SizedBox(height: gap), // gap between rectangles
            // Group 1 - Main Panel (dynamic height, vertically centered)
            _buildMainPanel(scale, mainPanelHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double scale) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        width: 62 * scale,
        height: 28 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(15 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 35 * scale,
              offset: Offset(3 * scale, 4 * scale),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bookmark button - toggles delete mode
            GestureDetector(
              onTap: _toggleDeleteMode,
              child: Icon(
                Icons.bookmark_rounded,
                size: 16 * scale,
                color: const Color(0xFFFE5F57), // Red #FE5F57
              ),
            ),
            // Mic icon
            Icon(
              Icons.mic_rounded,
              size: 16 * scale,
              color: widget.isVoiceRecording
                  ? Colors.red
                  : const Color(0xFF9A9A9A), // Gray #9A9A9A
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDeleteMode ? '삭제 모드: 북마크를 눌러 삭제하세요' : '삭제 모드 종료'),
          duration: const Duration(seconds: 2),
          backgroundColor: _isDeleteMode ? const Color(0xFFFE5F57) : null,
        ),
      );
    }
  }

  Widget _buildMainPanel(double scale, double height) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        width: 62 * scale,
        height: height * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 35 * scale,
              offset: Offset(3 * scale, 4 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile section (Rectangle 15: 42x42 at relative position 10,10)
            _buildProfileSection(scale),

            SizedBox(height: 8 * scale),

            // Gesture toggle (Component 3: 42x42 at relative position 10,60)
            _buildGestureToggle(scale),

            // Divider (Line 1: below gesture toggle)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 8 * scale,
              ),
              child: Container(
                height: 0.8 * scale,
                color: const Color(0xFF9A9A9A),
              ),
            ),

            // Bookmarks - stacked between divider and + button
            ..._buildBookmarksList(scale),

            // Add bookmark button (+ button at bottom)
            _buildAddBookmarkButton(scale),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(double scale) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10 * scale,
        left: 10 * scale,
        right: 10 * scale,
      ),
      child: GestureDetector(
        onTap: widget.onProfileTap,
        child: SizedBox(
          width: 42 * scale,
          height: 42 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Profile image (Rectangle 15: 42x42 white box with drop shadow)
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 1 * scale,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10 * scale),
                  child: _userInfo != null && _userInfo!['profileUrl'] != null
                      ? Image.network(
                          _userInfo!['profileUrl'],
                          width: 42 * scale,
                          height: 42 * scale,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 42 * scale,
                              height: 42 * scale,
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: 24 * scale),
                            );
                          },
                        )
                      : Container(
                          width: 42 * scale,
                          height: 42 * scale,
                          color: Colors.grey[300],
                          child: Icon(Icons.person, size: 24 * scale),
                        ),
                ),
              ),
              // Badge at bottom-right corner of profile
              if (_userInfo != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3 * scale,
                      vertical: 1 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: _userInfo!['subscriptStatus'] == 'PAID'
                          ? const Color(0xFF4E9CFF)
                          : const Color(0xFF9A9A9A),
                      borderRadius: BorderRadius.circular(3 * scale),
                    ),
                    child: Text(
                      _userInfo!['subscriptStatus'] == 'PAID' ? 'pro' : 'free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureToggle(double scale) {
    // Component 3: Toggle button - 42x42
    // Rectangle 16: white background
    // Component 2: toggle switch (blue track + white circle)
    // "제스처" text below
    return GestureDetector(
      onTap: () => widget.onGestureToggle(!widget.isGestureEnabled),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10 * scale),
        width: 42 * scale,
        height: 42 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 1 * scale,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Toggle switch
            Container(
              width: 32 * scale,
              height: 18 * scale,
              decoration: BoxDecoration(
                color: widget.isGestureEnabled
                    ? const Color(0xFF4E9CFF) // Blue when ON
                    : Colors.grey[400], // Gray when OFF
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: widget.isGestureEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1 * scale),
                  width: 16 * scale,
                  height: 16 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 5 * scale,
                        offset: Offset(-2 * scale, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 2 * scale),
            // "제스처" text
            Text(
              '제스처',
              style: TextStyle(
                fontSize: 6 * scale,
                fontWeight: FontWeight.w500,
                color: widget.isGestureEnabled
                    ? const Color(0xFF4E9CFF)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBookmarksList(double scale) {
    // Bookmark icons: Each 42x42 white box with drop shadow
    // Load favicons from Google Favicon API
    // Stacked between divider and + button
    return widget.bookmarks.map((bookmark) {
      return InkWell(
        onTap: () {
          if (_isDeleteMode) {
            // Delete mode: delete bookmark
            _deleteBookmark(bookmark);
          } else {
            // Normal mode: navigate to bookmark
            widget.onBookmarkTap(bookmark.url);
          }
        },
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 4 * scale,
              ),
              width: 42 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 1 * scale,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10 * scale),
                child: _buildFavicon(bookmark.url, scale),
              ),
            ),
            // Show X indicator when in delete mode
            if (_isDeleteMode)
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 4 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24 * scale,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    await BookmarkService.deleteBookmark(bookmark.url);
    widget.onBookmarksChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('북마크가 삭제되었습니다: ${bookmark.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAddBookmarkButton(double scale) {
    // + button at the bottom - same style as bookmark buttons
    // Opens dialog to add new bookmark
    return InkWell(
      onTap: _showAddBookmarkDialog,
      child: Container(
        margin: EdgeInsets.only(
          left: 10 * scale,
          right: 10 * scale,
          top: 4 * scale,
          bottom: 10 * scale,
        ),
        width: 42 * scale,
        height: 42 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 1 * scale,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          size: 24 * scale,
          color: const Color(0xFF4E9CFF),
        ),
      ),
    );
  }

  Future<void> _showAddBookmarkDialog() async {
    // Default to current URL
    final currentUrl = widget.currentUrl.isNotEmpty ? widget.currentUrl : '';

    // Extract default name from URL
    String defaultName = '';
    if (currentUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(currentUrl);
        defaultName = uri.host.isNotEmpty ? uri.host : currentUrl;
        // Remove 'www.' prefix if exists
        if (defaultName.startsWith('www.')) {
          defaultName = defaultName.substring(4);
        }
      } catch (e) {
        defaultName = currentUrl;
      }
    }

    final nameController = TextEditingController();
    final urlController = TextEditingController(text: currentUrl);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('북마크 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '이름',
                hintText: defaultName.isNotEmpty ? defaultName : '예: Google',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: '예: https://google.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    // Get values before disposing
    final name = nameController.text.trim();
    final url = urlController.text.trim();

    // Wait for dialog animation to complete before disposing
    await Future.delayed(const Duration(milliseconds: 100));

    nameController.dispose();
    urlController.dispose();

    // Only process if dialog returned true (not null or false)
    if (result == true && mounted) {
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재 페이지가 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Use default name if user didn't enter one
      final finalName = name.isNotEmpty ? name : defaultName;

      if (finalName.isNotEmpty) {
        final success = await BookmarkService.addBookmark(finalName, url);

        if (success) {
          widget.onBookmarksChanged();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('북마크가 추가되었습니다: $finalName'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 존재하는 북마크입니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  Widget _buildFavicon(String url, double scale) {
    // Extract domain from URL
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return _buildFallbackIcon(url, scale);
    }

    if (uri.host.isEmpty) {
      return _buildFallbackIcon(url, scale);
    }

    // Use Google's Favicon service
    final faviconUrl =
        'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';

    return Image.network(
      faviconUrl,
      width: 42 * scale,
      height: 42 * scale,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackIcon(url, scale);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 20 * scale,
            height: 20 * scale,
            child: CircularProgressIndicator(
              strokeWidth: 2 * scale,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon(String url, double scale) {
    // Fallback: show first letter of domain
    String letter = 'B';
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        letter = uri.host[0].toUpperCase();
      }
    } catch (e) {
      letter = url.isNotEmpty ? url[0].toUpperCase() : 'B';
    }

    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
