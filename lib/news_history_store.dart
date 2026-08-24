import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NewsHistoryItem {
  const NewsHistoryItem({
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.source,
    required this.viewedAt,
  });

  final String title;
  final String url;
  final String thumbnailUrl;
  final String source;
  final DateTime viewedAt;

  String get id => url.isNotEmpty ? url : title;

  Map<String, String> toJson() => {
    'title': title,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'source': source,
    'viewedAt': viewedAt.toIso8601String(),
  };

  factory NewsHistoryItem.fromJson(Map<String, dynamic> json) {
    return NewsHistoryItem(
      title: json['title']?.toString() ?? 'タイトルなし',
      url: json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      viewedAt:
          DateTime.tryParse(json['viewedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NewsHistoryStore {
  static const _storageKey = 'news_history';
  static const _cachedNewsKey = 'cached_news';
  static const _cachedNewsTimeKey = 'cached_news_time';
  static const _maxItems = 100;

  static Future<List<NewsHistoryItem>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_storageKey) ?? [];
    final items = <NewsHistoryItem>[];
    for (final value in values) {
      try {
        items.add(
          NewsHistoryItem.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } on FormatException {
        // Ignore malformed local cache entries.
      }
    }
    await _migrateCachedNews(preferences, items);
    items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return items;
  }

  static Future<void> _migrateCachedNews(
    SharedPreferences preferences,
    List<NewsHistoryItem> items,
  ) async {
    final cachedNews = preferences.getString(_cachedNewsKey);
    final cachedTime = preferences.getString(_cachedNewsTimeKey);
    if (cachedNews == null || cachedTime == null) return;

    try {
      final news = Map<String, dynamic>.from(jsonDecode(cachedNews) as Map);
      final item = NewsHistoryItem(
        title: news['title']?.toString() ?? 'タイトルなし',
        url: news['url']?.toString() ?? '',
        thumbnailUrl: news['thumbnail_url']?.toString() ?? '',
        source: news['source']?.toString() ?? '',
        viewedAt: DateTime.tryParse(cachedTime) ?? DateTime.now(),
      );
      if (!items.any((existing) => existing.id == item.id)) {
        items.add(item);
        await _save(items.take(_maxItems).toList());
      }
    } on FormatException {
      // Ignore malformed cache entries.
    }
  }

  static Future<void> saveFromNews(
    Map<String, dynamic> news,
    DateTime viewedAt,
  ) async {
    final items = await load();
    final item = NewsHistoryItem(
      title: news['title']?.toString() ?? 'タイトルなし',
      url: news['url']?.toString() ?? '',
      thumbnailUrl: news['thumbnail_url']?.toString() ?? '',
      source: news['source']?.toString() ?? '',
      viewedAt: viewedAt,
    );
    items.removeWhere((existing) => existing.id == item.id);
    items.insert(0, item);
    await _save(items.take(_maxItems).toList());
  }

  static Future<void> _save(List<NewsHistoryItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
