import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';

class Sidebar extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final String currentUrl;
  final Function(String) onBookmarkTap;
  final bool isGestureEnabled;
  final Function(bool) onGestureToggle;
  final VoidCallback onBookmarksChanged;

  const Sidebar({
    super.key,
    required this.bookmarks,
    required this.currentUrl,
    required this.onBookmarkTap,
    required this.isGestureEnabled,
    required this.onGestureToggle,
    required this.onBookmarksChanged,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isDeleteMode = false;

  Future<void> _addCurrentPageToBookmarks() async {
    final String currentUrl = widget.currentUrl;
    final String currentTitle = _getTitleFromUrl(currentUrl);

    // 다이얼로그로 이름 입력받기
    final TextEditingController nameController = TextEditingController(text: currentTitle);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이름', style: TextStyle(fontSize: 12, color: Colors.grey)),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: '즐겨찾기 이름',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text('URL', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              currentUrl,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final success = await BookmarkService.addBookmark(
        nameController.text,
        currentUrl,
      );

      if (success) {
        widget.onBookmarksChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('즐겨찾기에 추가되었습니다')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 즐겨찾기에 있습니다')),
          );
        }
      }
    }
  }

  String _getTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceAll('www.', '');
      return host.split('.').first.toUpperCase();
    } catch (e) {
      return 'New Bookmark';
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 삭제'),
        content: Text('${bookmark.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BookmarkService.deleteBookmark(bookmark.url);
      widget.onBookmarksChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bookmark.name}이(가) 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.bookmark, size: 32, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  '즐겨찾기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Gesture Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(
                  widget.isGestureEnabled ? Icons.videocam : Icons.videocam_off,
                  color: widget.isGestureEnabled ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  '제스처',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
                Switch(
                  value: widget.isGestureEnabled,
                  onChanged: widget.onGestureToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Add/Delete Mode Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addCurrentPageToBookmarks,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isDeleteMode = !_isDeleteMode;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: _isDeleteMode ? Colors.red : Colors.grey[300],
                      foregroundColor: _isDeleteMode ? Colors.white : Colors.grey[700],
                    ),
                    child: Icon(_isDeleteMode ? Icons.close : Icons.delete, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bookmarks List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = widget.bookmarks[index];
                final isActive = widget.currentUrl.contains(
                  Uri.parse(bookmark.url).host,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Material(
                    color: isActive ? Colors.blue[50] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _isDeleteMode
                          ? () => _deleteBookmark(bookmark)
                          : () => widget.onBookmarkTap(bookmark.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                // Favicon 이미지
                                Image.network(
                                  bookmark.faviconUrl,
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _getIconForUrl(bookmark.url),
                                      size: 32,
                                      color: _isDeleteMode
                                          ? Colors.red
                                          : (isActive ? Colors.blue : Colors.grey[600]),
                                    );
                                  },
                                ),
                                if (_isDeleteMode)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookmark.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDeleteMode
                                    ? Colors.red
                                    : (isActive
                                        ? Colors.blue[700]
                                        : Colors.grey[700]),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForUrl(String url) {
    if (url.contains('google.com')) return Icons.search;
    if (url.contains('youtube.com')) return Icons.play_circle;
    if (url.contains('github.com')) return Icons.code;
    if (url.contains('flutter.dev')) return Icons.flutter_dash;
    return Icons.language;
  }
}
