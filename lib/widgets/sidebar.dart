import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final List<Map<String, String>> bookmarks;
  final String currentUrl;
  final Function(String) onBookmarkTap;
  final bool isGestureEnabled;
  final Function(bool) onGestureToggle;

  const Sidebar({
    super.key,
    required this.bookmarks,
    required this.currentUrl,
    required this.onBookmarkTap,
    required this.isGestureEnabled,
    required this.onGestureToggle,
  });

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
                  isGestureEnabled ? Icons.videocam : Icons.videocam_off,
                  color: isGestureEnabled ? Colors.green : Colors.grey,
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
                  value: isGestureEnabled,
                  onChanged: onGestureToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bookmarks List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                final isActive = currentUrl.contains(
                  Uri.parse(bookmark['url']!).host,
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
                      onTap: () => onBookmarkTap(bookmark['url']!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForUrl(bookmark['url']!),
                              size: 32,
                              color: isActive ? Colors.blue : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookmark['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive
                                    ? Colors.blue[700]
                                    : Colors.grey[700],
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
