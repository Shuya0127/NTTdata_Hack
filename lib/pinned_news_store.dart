import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'testlogin/test_login_page.dart';

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
      await _syncPinnedNews(pinnedNews);
      return false;
    }

    pinnedNews.add(news);
    await _save(pinnedNews);
    await _syncPinnedNews(pinnedNews);
    return true;
  }

  /// 端末に既に保存されているピン留めをSupabaseへ同期する。
  static Future<void> syncCurrentUserPins() async {
    await _syncPinnedNews(await load());
  }

  static Future<void> _syncPinnedNews(List<PinnedNews> pinnedNews) async {
    final userId =
        TestSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('pinned_news')
          .delete()
          .eq('user_id', userId);
      final rows = pinnedNews
          .where((news) => news.url.isNotEmpty)
          .map(
            (news) => {
              'user_id': userId,
              'news_url': news.url,
              'title': news.title,
              'thumbnail_url': news.thumbnailUrl,
              'source': news.source,
              'pinned_at': news.pinnedAt.toIso8601String(),
            },
          )
          .toList();
      if (rows.isNotEmpty) {
        await Supabase.instance.client.from('pinned_news').insert(rows);
      }
    } catch (_) {
      // テーブル未作成やRLS設定前でも、端末内のピン留めは利用できる。
    }
  }

  static Future<void> _save(List<PinnedNews> pinnedNews) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      pinnedNews.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
