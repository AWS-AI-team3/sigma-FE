import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String name;
  final String url;

  Bookmark({required this.name, required this.url});

  /// Favicon URL (Google Favicon API 사용)
  String get faviconUrl {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.isEmpty ? url : uri.host;
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } catch (e) {
      return 'https://www.google.com/s2/favicons?domain=google.com&sz=64';
    }
  }

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }
}

class BookmarkService {
  static const String _key = 'bookmarks';

  // 기본 즐겨찾기
  static final List<Bookmark> _defaultBookmarks = [
    Bookmark(name: 'Google', url: 'https://www.google.com'),
    Bookmark(name: 'YouTube', url: 'https://www.youtube.com'),
    Bookmark(name: 'GitHub', url: 'https://github.com'),
    Bookmark(name: 'Flutter', url: 'https://flutter.dev'),
  ];

  // 모든 즐겨찾기 로드
  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString(_key);

    if (bookmarksJson == null) {
      // 첫 실행 시 기본 즐겨찾기 저장
      await _saveBookmarks(_defaultBookmarks);
      return _defaultBookmarks;
    }

    try {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded.map((item) => Bookmark.fromJson(item)).toList();
    } catch (e) {
      print('❌ Failed to load bookmarks: $e');
      return _defaultBookmarks;
    }
  }

  // 즐겨찾기 추가
  static Future<bool> addBookmark(String name, String url) async {
    try {
      final bookmarks = await getBookmarks();

      // 중복 체크 (URL 기준)
      if (bookmarks.any((b) => b.url == url)) {
        print('⚠️ Bookmark already exists: $url');
        return false;
      }

      bookmarks.add(Bookmark(name: name, url: url));
      await _saveBookmarks(bookmarks);

      print('✅ Bookmark added: $name');
      return true;
    } catch (e) {
      print('❌ Failed to add bookmark: $e');
      return false;
    }
  }

  // 즐겨찾기 삭제
  static Future<bool> deleteBookmark(String url) async {
    try {
      final bookmarks = await getBookmarks();
      bookmarks.removeWhere((b) => b.url == url);
      await _saveBookmarks(bookmarks);

      print('✅ Bookmark deleted: $url');
      return true;
    } catch (e) {
      print('❌ Failed to delete bookmark: $e');
      return false;
    }
  }

  // 즐겨찾기 업데이트 (이름 변경)
  static Future<bool> updateBookmark(String url, String newName) async {
    try {
      final bookmarks = await getBookmarks();
      final index = bookmarks.indexWhere((b) => b.url == url);

      if (index == -1) {
        print('⚠️ Bookmark not found: $url');
        return false;
      }

      bookmarks[index] = Bookmark(name: newName, url: url);
      await _saveBookmarks(bookmarks);

      print('✅ Bookmark updated: $newName');
      return true;
    } catch (e) {
      print('❌ Failed to update bookmark: $e');
      return false;
    }
  }

  // 즐겨찾기 존재 여부 확인
  static Future<bool> isBookmarked(String url) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.url == url);
  }

  // 음성 명령으로 즐겨찾기 찾기
  static Future<Bookmark?> findBookmarkByVoice(String voiceInput) async {
    final bookmarks = await getBookmarks();
    final input = voiceInput.toLowerCase().trim();

    print('🔍 Finding bookmark for: "$input"');
    print('🔍 Available bookmarks: ${bookmarks.map((b) => b.name).join(", ")}');

    // 한글-영어 키워드 매핑
    final keywordMap = {
      '구글': ['google', 'google.com'],
      '유튜브': ['youtube', 'youtube.com'],
      '깃허브': ['github', 'github.com'],
      '플러터': ['flutter', 'flutter.dev'],
      '네이버': ['naver', 'naver.com'],
    };

    // 1. 정확한 이름 매칭
    for (final bookmark in bookmarks) {
      if (bookmark.name.toLowerCase() == input) {
        print('✅ Exact name match: ${bookmark.name}');
        return bookmark;
      }
    }

    // 2. 키워드 매칭 (한글 → 영어)
    print('🔍 Step 2: Checking keyword matching...');
    for (final entry in keywordMap.entries) {
      if (input.contains(entry.key)) {
        print('  ✓ Input contains "${entry.key}", checking keywords: ${entry.value}');
        for (final keyword in entry.value) {
          for (final bookmark in bookmarks) {
            if (bookmark.name.toLowerCase().contains(keyword) ||
                bookmark.url.toLowerCase().contains(keyword)) {
              print('✅ STEP 2 MATCH - Keyword: ${entry.key} → $keyword → ${bookmark.name}');
              return bookmark;
            }
          }
        }
      }
    }
    print('🔍 Step 2: No keyword match');

    // 3. URL 부분 매칭 (입력이 3글자 이상일 때만)
    print('🔍 Step 3: Checking URL matching...');
    if (input.length >= 3) {
      for (final bookmark in bookmarks) {
        if (bookmark.url.toLowerCase().contains(input)) {
          print('✅ Matched by URL: $input in ${bookmark.url}');
          return bookmark;
        }
      }
    }

    // 4. 이름 부분 매칭 (bookmark 이름이 입력에 포함될 때만)
    print('🔍 Step 4: Checking name matching...');
    for (final bookmark in bookmarks) {
      final bookmarkName = bookmark.name.toLowerCase();
      print('  Checking if "${bookmarkName}" contains "$input"');
      // 입력이 즐겨찾기 이름을 포함하는 경우만 (역방향은 제거)
      if (bookmarkName.contains(input) && input.length >= 2) {
        print('✅ STEP 4 MATCH - Name contains: $input in ${bookmark.name}');
        return bookmark;
      }
    }
    print('🔍 Step 4: No name match');

    print('❌ NO BOOKMARK FOUND, returning null');
    return null;
  }

  // 내부: 즐겨찾기 저장
  static Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = json.encode(
      bookmarks.map((b) => b.toJson()).toList(),
    );
    await prefs.setString(_key, bookmarksJson);
  }

  // 즐겨찾기 초기화 (기본값으로 복구)
  static Future<void> resetToDefault() async {
    await _saveBookmarks(_defaultBookmarks);
    print('✅ Bookmarks reset to default');
  }
}
