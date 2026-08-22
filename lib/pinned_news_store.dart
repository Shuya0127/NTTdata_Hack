import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PinnedNews {
  const PinnedNews({
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.source,
    required this.pinnedAt,
  });

  final String title;
  final String url;
  final String thumbnailUrl;
  final String source;
  final DateTime pinnedAt;

  String get id => url.isNotEmpty ? url : title;

  Map<String, String> toJson() => {
    'title': title,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'source': source,
    'pinnedAt': pinnedAt.toIso8601String(),
  };

  factory PinnedNews.fromJson(Map<String, dynamic> json) {
    return PinnedNews(
      title: json['title']?.toString() ?? 'タイトルなし',
      url: json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      pinnedAt:
          DateTime.tryParse(json['pinnedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PinnedNewsStore {
  static const _storageKey = 'pinned_news';

  static Future<List<PinnedNews>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedNews = preferences.getStringList(_storageKey) ?? [];

    final pinnedNews = <PinnedNews>[];
    for (final item in savedNews) {
      try {
        pinnedNews.add(
          PinnedNews.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on FormatException {
        // Ignore malformed cached entries so valid pins can still load.
      }
    }

    pinnedNews.sort((a, b) => b.pinnedAt.compareTo(a.pinnedAt));
    return pinnedNews;
  }

  static Future<bool> toggle(PinnedNews news) async {
    final pinnedNews = await load();
    final existingIndex = pinnedNews.indexWhere((item) => item.id == news.id);

    if (existingIndex >= 0) {
      pinnedNews.removeAt(existingIndex);
      await _save(pinnedNews);
      return false;
    }

    pinnedNews.add(news);
    await _save(pinnedNews);
    return true;
  }

  static Future<void> _save(List<PinnedNews> pinnedNews) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      pinnedNews.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
