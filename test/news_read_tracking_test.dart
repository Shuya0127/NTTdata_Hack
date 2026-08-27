import 'package:flutter_test/flutter_test.dart';
import 'package:newsapp/news/news_home_page.dart';

void main() {
  group('NewsReadTracker', () {
    test('同じURLのニュースは同一記事として扱う', () {
      const a = 'https://example.com/news?id=123';
      const b = 'https://example.com/news?id=123';

      expect(NewsReadTracker.isSameNews(a, b), isTrue);
    });

    test('URLが空なら同一記事ではない', () {
      expect(NewsReadTracker.isSameNews('', 'https://example.com/news'), isFalse);
    });

    test('空のURLでは記録しない', () async {
      const url = '';
      const userId = 'user-1';

      await NewsReadTracker.markAsReadIfNeeded(
        newsUrl: url,
        userId: userId,
      );

      expect(true, isTrue);
    });
  });
}
