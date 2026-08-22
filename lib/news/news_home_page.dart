import '../services/visited_countries_store.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../add_friend.dart';
import '../pinned_news_store.dart';
import '../profile_page.dart';
import '../settings_page.dart';
import '../world_map_page.dart';

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  static Map<String, dynamic>? _activeNews;
  static DateTime? _activeNewsSelectedAt;

  Future<Map<String, dynamic>?>? _newsFuture;

  Timer? _newsRefreshTimer;

  // ニュースを切り替える間隔
  static const Duration _refreshInterval = Duration(minutes: 5);

  // SharedPreferencesに保存するときの名前
  static const String _cachedNewsKey = 'cached_news';
  static const String _cachedNewsTimeKey = 'cached_news_time';

  DateTime? _selectedAt;
  String? _currentNewsUrl;
  Set<String> _pinnedNewsIds = {};

  @override
  void initState() {
    super.initState();

    _restoreActiveNews();
    _loadPinnedNews();
  }

  void _restoreActiveNews() {
    final activeNews = _activeNews;
    final selectedAt = _activeNewsSelectedAt;

    if (activeNews == null || selectedAt == null) {
      return;
    }

    if (DateTime.now().difference(selectedAt) >= _refreshInterval) {
      _activeNews = null;
      _activeNewsSelectedAt = null;
      return;
    }

    _selectedAt = selectedAt;
    _currentNewsUrl = activeNews['url']?.toString();
    _newsFuture = Future.value(activeNews);
    _scheduleNextRefresh();
  }

  void _saveActiveNews(Map<String, dynamic> news, DateTime selectedAt) {
    _activeNews = Map<String, dynamic>.from(news);
    _activeNewsSelectedAt = selectedAt;
  }

  Future<void> _loadPinnedNews() async {
    final pinnedNews = await PinnedNewsStore.load();

    if (!mounted) return;

    setState(() {
      _pinnedNewsIds = pinnedNews.map((news) => news.id).toSet();
    });
  }

  Future<void> _togglePinnedNews({
    required String title,
    required String url,
    required String thumbnailUrl,
    required String source,
  }) async {
    final news = PinnedNews(
      title: title,
      url: url,
      thumbnailUrl: thumbnailUrl,
      source: source,
      pinnedAt: DateTime.now(),
    );
    final isPinned = await PinnedNewsStore.toggle(news);

    if (!mounted) return;

    setState(() {
      if (isPinned) {
        _pinnedNewsIds.add(news.id);
      } else {
        _pinnedNewsIds.remove(news.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isPinned ? 'ニュースをピン留めしました' : 'ピン留めを解除しました')),
    );
  }

  // ============================================================
  // 起動時に表示するニュースを決定
  // ============================================================

  Future<Map<String, dynamic>?> _loadNews() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedNewsJson = prefs.getString(_cachedNewsKey);

    final cachedTimeText = prefs.getString(_cachedNewsTimeKey);

    // 保存済みニュースが存在する場合
    if (cachedNewsJson != null && cachedTimeText != null) {
      try {
        final cachedTime = DateTime.parse(cachedTimeText);

        final decoded = jsonDecode(cachedNewsJson);

        final cachedNews = Map<String, dynamic>.from(decoded as Map);

        final elapsed = DateTime.now().difference(cachedTime);

        _currentNewsUrl = cachedNews['url']?.toString();

        // まだ5分経っていない
        if (elapsed < _refreshInterval) {
          _selectedAt = cachedTime;
          _saveActiveNews(cachedNews, cachedTime);

          debugPrint('保存済みニュースを表示します');

          debugPrint('経過時間: ${elapsed.inSeconds}秒');

          _scheduleNextRefresh();

          return cachedNews;
        }
      } catch (e) {
        debugPrint('保存済みニュース読み込みエラー: $e');
      }
    }

    // 保存データがない、または5分以上経過
    return _getRandomNews();
  }

  // ============================================================
  // Supabaseから
  // 「画像URLあり」かつ「最新100件」のニュースを取得
  // その中からランダムに1件選択
  // ============================================================

  Future<Map<String, dynamic>?> _getRandomNews() async {
    try {
      final data = await Supabase.instance.client
          .from('news')
          .select(
            'title, url, content, thumbnail_url, source, published_at, country',
          )
          // thumbnail_urlが空ではないニュースだけ
          .neq('thumbnail_url', '')
          // 新しいニュースから順番に
          .order('published_at', ascending: false)
          // 最新100件だけ取得
          .limit(100);

      debugPrint('Supabaseから取得したニュース数: ${data.length}');

      if (data.isEmpty) {
        debugPrint('画像付きニュースがありません');

        return null;
      }

      // ========================================================
      // 念のため、Flutter側でも画像URLをチェック
      // ========================================================

      var validNews = data.where((news) {
        final imageUrl = news['thumbnail_url']?.toString().trim() ?? '';

        if (imageUrl.isEmpty) {
          return false;
        }

        final uri = Uri.tryParse(imageUrl);

        if (uri == null) {
          return false;
        }

        return uri.scheme == 'http' || uri.scheme == 'https';
      }).toList();

      debugPrint('有効な画像URLを持つニュース数: ${validNews.length}');

      if (validNews.isEmpty) {
        debugPrint('有効な画像URLを持つニュースがありません');

        return null;
      }

      // ========================================================
      // 前回と同じ記事をできるだけ避ける
      // ========================================================

      if (_currentNewsUrl != null && validNews.length > 1) {
        final filteredNews = validNews.where((news) {
          final newsUrl = news['url']?.toString() ?? '';

          return newsUrl != _currentNewsUrl;
        }).toList();

        if (filteredNews.isNotEmpty) {
          validNews = filteredNews;
        }
      }

      // ========================================================
      // ランダム選択
      // ========================================================

      final random = Random();

      final randomIndex = random.nextInt(validNews.length);

      final randomNews = Map<String, dynamic>.from(validNews[randomIndex]);

      debugPrint('ランダムに選ばれたニュース: $randomNews');

      debugPrint('画像URL: ${randomNews['thumbnail_url']}');

      // 現在の記事URLを保存
      _currentNewsUrl = randomNews['url']?.toString();

      // 選択した時刻を保存
      final now = DateTime.now();

      _selectedAt = now;
      _saveActiveNews(randomNews, now);

      // ========================================================
      // 端末にニュースを保存
      // ========================================================

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_cachedNewsKey, jsonEncode(randomNews));

      await prefs.setString(_cachedNewsTimeKey, now.toIso8601String());

      // 5分後に次の記事へ変更
      _scheduleNextRefresh();

      return randomNews;
    } catch (e) {
      debugPrint('Supabase取得エラー: $e');

      rethrow;
    }
  }

  // ============================================================
  // 次にニュースを取得できる時刻を設定
  // ============================================================

  void _scheduleNextRefresh() {
    // 既存Timerがあれば停止
    _newsRefreshTimer?.cancel();

    final selectedAt = _selectedAt ?? DateTime.now();

    final elapsed = DateTime.now().difference(selectedAt);

    var remaining = _refreshInterval - elapsed;

    // すでに5分経っている場合
    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    debugPrint('次のニュース更新まで ${remaining.inSeconds} 秒');

    _newsRefreshTimer = Timer(remaining, _resetNews);
  }

  // ============================================================
  // 5分経過時に取得ボタンを再表示
  // ============================================================

  void _resetNews() {
    if (!mounted) {
      return;
    }

    debugPrint('5分経過したためニュース取得を再度受け付けます');

    setState(() {
      _newsFuture = null;
    });

    _activeNews = null;
    _activeNewsSelectedAt = null;
  }

  // ============================================================
  // エラー時などの再読み込み
  // ============================================================

  void _reloadNews() {
    setState(() {
      _newsFuture = _loadNews();
    });
  }

  // ============================================================
  // Timerを終了
  // ============================================================

  @override
  void dispose() {
    _newsRefreshTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // ニュースURLを開く
  // ============================================================

  Future<void> _openNewsUrl(String url) async {
    if (url.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ニュースURLが登録されていません')));

      return;
    }

    final Uri? newsUri = Uri.tryParse(url.trim());

    if (newsUri == null ||
        !(newsUri.scheme == 'http' || newsUri.scheme == 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ニュースURLが正しくありません')));

      return;
    }

    try {
      final bool opened = await launchUrl(
        newsUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ニュースサイトを開けませんでした')));
      }
    } catch (e) {
      debugPrint('URLを開く際のエラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ニュースサイトを開けませんでした: $e')));
    }
  }

  // ============================================================
  // 国コード
  // ============================================================

  String _countryLabel(String country) {
    switch (country.toUpperCase()) {
      case 'GB':
        return '🇬🇧 UK';

      case 'JP':
        return '🇯🇵 JAPAN';

      case 'US':
        return '🇺🇸 USA';

      case 'AU':
        return '🇦🇺 AUSTRALIA';

      case 'ANY':
        return '🌍 WORLD';

      default:
        return '🌍 WORLD';
    }
  }

  // ============================================================
  // ニュース画像
  // ============================================================

  Widget _buildNewsImage(String thumbnailUrl) {
    if (thumbnailUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.network(
          thumbnailUrl,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,

          // 読み込み中
          loadingBuilder:
              (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return Container(
                  color: const Color(0xFFE6ECF4),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },

          // 画像読み込み失敗
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                debugPrint('画像読み込みエラー: $error');

                return _buildImagePlaceholder();
              },
        ),
      ),
    );
  }

  // ============================================================
  // 画像が読み込めなかった場合
  // ============================================================

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECF4),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 55, color: Color(0xFF52657A)),
      ),
    );
  }

  // ============================================================
  // メイン画面
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      bottomNavigationBar: const _BottomNavigation(),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // ヘッダー
              // =================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ニュースBeReal',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddFriendPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 27),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // =================================================
              // 今日のニュース
              // =================================================
              if (_newsFuture == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF9AAEC6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.newspaper_outlined,
                        size: 54,
                        color: Color(0xFF52657A),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '今日のニュースを取得します',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ボタンを押すと、ニュースを表示します',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _reloadNews,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('ニュースを取得する'),
                      ),
                    ],
                  ),
                )
              else
                FutureBuilder<Map<String, dynamic>?>(
                  future: _newsFuture,
                  builder: (context, snapshot) {
                    // ---------------------------------------------
                    // 読み込み中
                    // ---------------------------------------------

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF9AAEC6),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'ニュースを取得しています...',
                                style: TextStyle(color: Color(0xFF667085)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // ---------------------------------------------
                    // エラー
                    // ---------------------------------------------

                    if (snapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              'ニュースの取得に失敗しました',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 20),

                            FilledButton(
                              onPressed: _reloadNews,
                              child: const Text('もう一度取得'),
                            ),
                          ],
                        ),
                      );
                    }

                    final news = snapshot.data;

                    // ---------------------------------------------
                    // ニュースなし
                    // ---------------------------------------------

                    if (news == null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF9AAEC6)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.article_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              'ニュースがありません',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            FilledButton(
                              onPressed: _reloadNews,
                              child: const Text('再読み込み'),
                            ),
                          ],
                        ),
                      );
                    }

                    // ---------------------------------------------
                    // データ取得成功
                    // ---------------------------------------------

                    final String title = news['title']?.toString() ?? 'タイトルなし';

                    final String url = news['url']?.toString() ?? '';

                    final String content = news['content']?.toString() ?? '';

                    final String thumbnailUrl =
                        news['thumbnail_url']?.toString() ?? '';

                    final String source = news['source']?.toString() ?? '';

                    final String country = news['country']?.toString() ?? 'ANY';

                    final newsId = url.isNotEmpty ? url : title;
                    final isPinned = _pinnedNewsIds.contains(newsId);

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF9AAEC6),
                          width: 1.5,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------------------------------
                          // 国・ニュース提供元
                          // ---------------------------------------

                          Row(
                            children: [
                              Text(
                                _countryLabel(country),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  source.isNotEmpty ? source : '今日のニュース',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ---------------------------------------
                          // 画像
                          // ---------------------------------------
                          _buildNewsImage(thumbnailUrl),

                          const SizedBox(height: 20),

                          // ---------------------------------------
                          // タイトル
                          // ---------------------------------------
                          Center(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _togglePinnedNews(
                                title: title,
                                url: url,
                                thumbnailUrl: thumbnailUrl,
                                source: source,
                              ),
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                              ),
                              label: Text(isPinned ? 'ピン留め済み' : 'ピン留めする'),
                            ),
                          ),

                          // ---------------------------------------
                          // 本文
                          // ---------------------------------------
                          if (content.isNotEmpty) ...[
                            const SizedBox(height: 15),

                            Text(
                              content.length > 180
                                  ? '${content.substring(0, 180)}...'
                                  : content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ---------------------------------------
                          // 記事を読む
                          // ---------------------------------------
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
            // 実際に何の値が渡っているかターミナルに出力して確認
            print('DEBUG: 渡された国名 -> $country'); 
            VisitedCountriesStore.markAsVisited(country);
            _openNewsUrl(url);
          },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF111827),
                                side: const BorderSide(
                                  color: Color(0xFFC5D1DF),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'タップして読む',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 28),

              // =================================================
              // フレンドのフィード
              // =================================================
              const Text(
                'フレンドのフィード',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 16),

              const _FriendFeedCard(),

              const SizedBox(height: 18),

              // =================================================
              // ロック部分
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 42,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF465A72),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.lock_outline, size: 42, color: Colors.black),

                    SizedBox(height: 22),

                    Text(
                      '🔒 あなたが今日のニュースを読むと、\n'
                      '友達のニュースとリアクションが見られます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// フレンド投稿
// ============================================================

class _FriendFeedCard extends StatelessWidget {
  const _FriendFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5D1DF), width: 1.3),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE5EDF7),
                child: Icon(Icons.person, color: Color(0xFF8799AF)),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User 1',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Text(
                      '2分前',
                      style: TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
                    ),
                  ],
                ),
              ),

              Text('🌐', style: TextStyle(fontSize: 25)),
            ],
          ),

          SizedBox(height: 18),

          Text(
            '友達がニュースを読みました。',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 18),

          Row(
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 22,
                color: Color(0xFF52657A),
              ),

              SizedBox(width: 6),

              Text(
                'いいね (2)',
                style: TextStyle(
                  color: Color(0xFF52657A),
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(width: 22),

              Icon(
                Icons.chat_bubble_outline,
                size: 21,
                color: Color(0xFF52657A),
              ),

              SizedBox(width: 6),

              Text(
                'コメント (5)',
                style: TextStyle(
                  color: Color(0xFF52657A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 下部ナビゲーション
// ============================================================

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD7DFE9))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, label: 'ホーム', active: true),

              _NavItem(
                icon: Icons.location_on_outlined,
                label: '地図',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WorldMapPage()),
                  );
                },
              ),

              _NavItem(
                icon: Icons.person_outline,
                label: 'マイページ',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),

              _NavItem(
                icon: Icons.settings_outlined,
                label: '設定',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 下部ナビゲーション項目
// ============================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF111827) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 27),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
