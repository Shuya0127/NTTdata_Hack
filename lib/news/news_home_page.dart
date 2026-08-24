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
import '../testlogin/test_login_page.dart'; // 👈 TestSessionを使うために追加

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

// --- 👇 変更点: with WidgetsBindingObserver を追加し、アプリの裏表を監視できるようにしました ---
class _NewsHomePageState extends State<NewsHomePage> with WidgetsBindingObserver {
  static Map<String, dynamic>? _activeNews;
  static DateTime? _activeNewsSelectedAt;

  Future<Map<String, dynamic>?>? _newsFuture;
  Timer? _newsRefreshTimer;

  static const Duration _refreshInterval = Duration(minutes: 5);

  static const String _cachedNewsKey = 'cached_news';
  static const String _cachedNewsTimeKey = 'cached_news_time';

  DateTime? _selectedAt;
  String? _currentNewsUrl;
  Set<String> _pinnedNewsIds = {};

  bool _hasReadNewsToday = false;

  @override
  void initState() {
    super.initState();
    // --- 👇 変更点: 画面が開いた時に監視をスタート ---
    WidgetsBinding.instance.addObserver(this);
    
    _restoreActiveNews();
    _loadPinnedNews();
    _checkIfUserReadNewsToday(); 
  }

  @override
  void dispose() {
    // --- 👇 変更点: 画面が閉じる時に監視をストップ ---
    WidgetsBinding.instance.removeObserver(this);
    
    _newsRefreshTimer?.cancel();
    super.dispose();
  }

  // --- 👇 変更点: ブラウザ等からアプリに戻ってきた時に呼ばれる処理を追加 ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('アプリがフォアグラウンドに復帰しました。既読チェックを再実行します。');
      _checkIfUserReadNewsToday();
    }
  }
  // ------------------------------------------------------------------

// ▼ 書き換え後
  Future<void> _checkIfUserReadNewsToday() async {
    final currentUserId = TestSession.currentUserId ?? Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // ユーザーの最新の閲覧履歴を1件だけ取得
      final response = await Supabase.instance.client
          .from('user_read_news')
          .select('created_at')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false) // 新しい順に並べる
          .limit(1);

      if (response.isNotEmpty) {
        // 最新の履歴の時間を取得
        final lastReadTimeString = response[0]['created_at'] as String;
        final lastReadTime = DateTime.parse(lastReadTimeString).toLocal(); // ローカル時間(JST)に変換

        // 今の時間と比較して、24時間以内なら「今日読んだ」と判定
        final now = DateTime.now();
        final difference = now.difference(lastReadTime);

        if (mounted) {
          setState(() {
            _hasReadNewsToday = difference.inHours < 24;
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _hasReadNewsToday = false;
          });
        }
      }
    } catch (e) {
      debugPrint('既読チェックエラー: $e');
    }
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

  Future<Map<String, dynamic>?> _loadNews() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNewsJson = prefs.getString(_cachedNewsKey);
    final cachedTimeText = prefs.getString(_cachedNewsTimeKey);

    if (cachedNewsJson != null && cachedTimeText != null) {
      try {
        final cachedTime = DateTime.parse(cachedTimeText);
        final decoded = jsonDecode(cachedNewsJson);
        final cachedNews = Map<String, dynamic>.from(decoded as Map);
        final elapsed = DateTime.now().difference(cachedTime);

        _currentNewsUrl = cachedNews['url']?.toString();

        if (elapsed < _refreshInterval) {
          _selectedAt = cachedTime;
          _saveActiveNews(cachedNews, cachedTime);
          _scheduleNextRefresh();
          return cachedNews;
        }
      } catch (e) {
        debugPrint('保存済みニュース読み込みエラー: $e');
      }
    }

    return _getRandomNews();
  }

  Future<Map<String, dynamic>?> _getRandomNews() async {
    try {
      final data = await Supabase.instance.client
          .from('news')
          .select('title, url, content, thumbnail_url, source, published_at, country')
          .neq('thumbnail_url', '')
          .order('published_at', ascending: false)
          .limit(100);

      if (data.isEmpty) return null;

      var validNews = data.where((news) {
        final imageUrl = news['thumbnail_url']?.toString().trim() ?? '';
        if (imageUrl.isEmpty) return false;
        final uri = Uri.tryParse(imageUrl);
        if (uri == null) return false;
        return uri.scheme == 'http' || uri.scheme == 'https';
      }).toList();

      if (validNews.isEmpty) return null;

      if (_currentNewsUrl != null && validNews.length > 1) {
        final filteredNews = validNews.where((news) {
          final newsUrl = news['url']?.toString() ?? '';
          return newsUrl != _currentNewsUrl;
        }).toList();

        if (filteredNews.isNotEmpty) {
          validNews = filteredNews;
        }
      }

      final random = Random();
      final randomIndex = random.nextInt(validNews.length);
      final randomNews = Map<String, dynamic>.from(validNews[randomIndex]);

      final currentUserId = TestSession.currentUserId ?? Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        try {
          await Supabase.instance.client.from('user_read_news').insert({
            'user_id': currentUserId,
            'news_url': randomNews['url']?.toString() ?? '',
          });
          debugPrint('DBにニュース閲覧履歴を保存しました');
          
          _checkIfUserReadNewsToday(); 

        } catch (e) {
          debugPrint('閲覧履歴の保存エラー: $e');
        }
      }

      _currentNewsUrl = randomNews['url']?.toString();
      final now = DateTime.now();

      _selectedAt = now;
      _saveActiveNews(randomNews, now);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedNewsKey, jsonEncode(randomNews));
      await prefs.setString(_cachedNewsTimeKey, now.toIso8601String());

      _scheduleNextRefresh();

      return randomNews;
    } catch (e) {
      debugPrint('Supabase取得エラー: $e');
      rethrow;
    }
  }

  void _scheduleNextRefresh() {
    _newsRefreshTimer?.cancel();
    final selectedAt = _selectedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(selectedAt);
    var remaining = _refreshInterval - elapsed;

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    _newsRefreshTimer = Timer(remaining, _resetNews);
  }

  void _resetNews() {
    if (!mounted) return;
    setState(() {
      _newsFuture = null;
    });
    _activeNews = null;
    _activeNewsSelectedAt = null;
  }

  void _reloadNews() {
    setState(() {
      _newsFuture = _loadNews();
    });
  }

  Future<void> _openNewsUrl(String url) async {
    if (url.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ニュースURLが登録されていません')));
      return;
    }

    final Uri? newsUri = Uri.tryParse(url.trim());
    if (newsUri == null || !(newsUri.scheme == 'http' || newsUri.scheme == 'https')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ニュースURLが正しくありません')));
      return;
    }

    try {
      final bool opened = await launchUrl(
        newsUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      // --- 👇 ここに追加：URLを開いた直後に既読チェックを再実行する 👇 ---
      _checkIfUserReadNewsToday();
      // --- 👆 ここまで 👆 ---

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ニュースサイトを開けませんでした')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ニュースサイトを開けませんでした: $e')));
    }
  }

  String _countryLabel(String country) {
    switch (country.toUpperCase()) {
      case 'GB': return '🇬🇧 UK';
      case 'JP': return '🇯🇵 JAPAN';
      case 'US': return '🇺🇸 USA';
      case 'AU': return '🇦🇺 AUSTRALIA';
      case 'ANY': return '🌍 WORLD';
      default: return '🌍 WORLD';
    }
  }

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
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(color: const Color(0xFFE6ECF4), child: const Center(child: CircularProgressIndicator()));
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return _buildImagePlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180, width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFE6ECF4), borderRadius: BorderRadius.circular(17)),
      child: const Center(child: Icon(Icons.image_outlined, size: 55, color: Color(0xFF52657A))),
    );
  }

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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ニュースBeReal',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -1, color: Color(0xFF111827)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFriendPage())),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 27),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 30)),
                ],
              ),
              const SizedBox(height: 25),

              if (_newsFuture == null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF9AAEC6), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.newspaper_outlined, size: 54, color: Color(0xFF52657A)),
                      const SizedBox(height: 16),
                      const Text('今日のニュースを取得します', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      const SizedBox(height: 8),
                      const Text('ボタンを押すと、ニュースを表示します', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
                      const SizedBox(height: 24),
                      FilledButton.icon(onPressed: _reloadNews, icon: const Icon(Icons.download_outlined), label: const Text('ニュースを取得する')),
                    ],
                  ),
                )
              else
                FutureBuilder<Map<String, dynamic>?>(
                  future: _newsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity, height: 350,
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF9AAEC6), width: 1.5),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('ニュースを取得しています...', style: TextStyle(color: Color(0xFF667085)))],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Container(
                        width: double.infinity, padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 50, color: Colors.red),
                            const SizedBox(height: 15),
                            const Text('ニュースの取得に失敗しました', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 20),
                            FilledButton(onPressed: _reloadNews, child: const Text('もう一度取得')),
                          ],
                        ),
                      );
                    }
                    final news = snapshot.data;
                    if (news == null) {
                      return Container(
                        width: double.infinity, padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF9AAEC6)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.article_outlined, size: 50, color: Colors.grey),
                            const SizedBox(height: 15),
                            const Text('ニュースがありません', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            FilledButton(onPressed: _reloadNews, child: const Text('再読み込み')),
                          ],
                        ),
                      );
                    }

                    final String title = news['title']?.toString() ?? 'タイトルなし';
                    final String url = news['url']?.toString() ?? '';
                    final String content = news['content']?.toString() ?? '';
                    final String thumbnailUrl = news['thumbnail_url']?.toString() ?? '';
                    final String source = news['source']?.toString() ?? '';
                    final String country = news['country']?.toString() ?? 'ANY';
                    final newsId = url.isNotEmpty ? url : title;
                    final isPinned = _pinnedNewsIds.contains(newsId);

                    return Container(
                      width: double.infinity, padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF9AAEC6), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_countryLabel(country), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(source.isNotEmpty ? source : '今日のニュース', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF667085)))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildNewsImage(thumbnailUrl),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.4, color: Color(0xFF111827))),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _togglePinnedNews(title: title, url: url, thumbnailUrl: thumbnailUrl, source: source),
                              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                              label: Text(isPinned ? 'ピン留め済み' : 'ピン留めする'),
                            ),
                          ),
                          if (content.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            Text(content.length > 180 ? '${content.substring(0, 180)}...' : content, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF667085))),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: OutlinedButton(
                              onPressed: () => _openNewsUrl(url),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF111827),
                                side: const BorderSide(color: Color(0xFFC5D1DF), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('タップして読む', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),

              if (_hasReadNewsToday) ...[
                const Text('今日のあなたのニュース', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 16),
                // 👇 自分自身の今日の閲覧履歴とリアクションを表示するウィジェット
                const _MyTodayNewsFeedCard(),
                const SizedBox(height: 28),

                const Text('フレンドのフィード', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 16),
                const _FriendFeedSection(),
                const SizedBox(height: 18),
              ] else ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
                  decoration: BoxDecoration(
                    color: const Color(0xFF465A72),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_outline, size: 42, color: Colors.black),
                      SizedBox(height: 22),
                      Text(
                        '🔒 あなたが今日のニュースを読むと、\n友達のニュースとリアクションが見られます',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- 👇 ファイルの末尾にある _FriendFeedSection 以降をすべて消して、以下を貼り付けます 👇 ---

class _FriendFeedSection extends StatefulWidget {
  const _FriendFeedSection();

  @override
  State<_FriendFeedSection> createState() => _FriendFeedSectionState();
}

class _FriendFeedSectionState extends State<_FriendFeedSection> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _feedItems = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final currentUserId = TestSession.currentUserId ?? client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('ログインIDが見つかりません');

      // 1. フレンドのIDリストを取得
      final sent = await client.from('friendships').select('receiver_id').eq('sender_id', currentUserId).eq('status', 'accepted');
      final received = await client.from('friendships').select('sender_id').eq('receiver_id', currentUserId).eq('status', 'accepted');

      List<String> friendIds = [];
      for (var row in sent) friendIds.add(row['receiver_id'].toString());
      for (var row in received) friendIds.add(row['sender_id'].toString());

      if (friendIds.isEmpty) {
        if (mounted) setState(() { _feedItems = []; _isLoading = false; });
        return;
      }

      // 2. 過去24時間以内の履歴を取得
      final yesterday = DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();
      final newsHistory = await client
          .from('user_read_news')
          .select('id, user_id, news_url, created_at')
          .filter('user_id', 'in', friendIds)
          .gte('created_at', yesterday)
          .order('created_at', ascending: false);

      // 3. データ結合（ニュースの詳細も取得する！）
      List<Map<String, dynamic>> enrichedFeed = [];
      for (var item in newsHistory) {
        final historyId = item['id'];
        final friendId = item['user_id'];
        final newsUrl = item['news_url'];

        // プロフィール取得
        final profile = await client.from('profiles').select('username').eq('id', friendId).maybeSingle();
        final username = profile?['username']?.toString() ?? 'ユーザー';

        // ニュース詳細取得（newsテーブルから引く）
        final newsList = await client.from('news').select('title, thumbnail_url, source').eq('url', newsUrl).limit(1);
        
        final newsTitle = (newsList.isNotEmpty) ? newsList[0]['title']?.toString() ?? 'タイトル不明' : 'タイトル不明';
        final newsThumbnail = (newsList.isNotEmpty) ? newsList[0]['thumbnail_url']?.toString() ?? '' : '';
        final newsSource = (newsList.isNotEmpty) ? newsList[0]['source']?.toString() ?? 'ニュースサイト' : 'ニュースサイト';

        // いいねとコメント
        final likes = await client.from('news_likes').select('user_id').eq('user_read_news_id', historyId);
        final isLikedByMe = likes.any((like) => like['user_id'] == currentUserId);
        final comments = await client.from('news_comments').select('id').eq('user_read_news_id', historyId);

        enrichedFeed.add({
          'history_id': historyId,
          'friend_id': friendId,
          'username': username,
          'news_url': newsUrl,
          'news_title': newsTitle,
          'news_thumbnail': newsThumbnail,
          'news_source': newsSource,
          'created_at': item['created_at'],
          'like_count': likes.length,
          'is_liked_by_me': isLikedByMe,
          'comment_count': comments.length,
        });
      }

      if (mounted) {
        setState(() {
          _feedItems = enrichedFeed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('フィード取得エラー: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
    if (_errorMessage != null) return Padding(padding: const EdgeInsets.all(20.0), child: Text('エラー:\n$_errorMessage', style: const TextStyle(color: Colors.red)));
    if (_feedItems.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('まだ友達のニュース履歴がありません。', style: TextStyle(color: Color(0xFF667085))));

    return Column(
      children: _feedItems.map((item) => _FriendFeedCard(item: item, onInteract: _loadFeed)).toList(),
    );
  }
}

class _FriendFeedCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onInteract;

  const _FriendFeedCard({required this.item, required this.onInteract});

  @override
  State<_FriendFeedCard> createState() => _FriendFeedCardState();
}

class _FriendFeedCardState extends State<_FriendFeedCard> {
  bool _isLiking = false;

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    try {
      final client = Supabase.instance.client;
      final currentUserId = TestSession.currentUserId ?? client.auth.currentUser?.id;
      final historyId = widget.item['history_id'];
      final isLiked = widget.item['is_liked_by_me'] as bool;

      if (isLiked) {
        await client.from('news_likes').delete().eq('user_read_news_id', historyId).eq('user_id', currentUserId!);
      } else {
        await client.from('news_likes').insert({'user_read_news_id': historyId, 'user_id': currentUserId});
      }
      widget.onInteract();
    } catch (e) {
      debugPrint('いいねエラー: $e');
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CommentSheet(historyId: widget.item['history_id']),
    ).then((_) => widget.onInteract()); // 閉じた時にフィードを更新（コメント数を反映）
  }

  Future<void> _openNews() async {
    final url = widget.item['news_url'] as String;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.item['is_liked_by_me'] as bool;
    final likeCount = widget.item['like_count'] as int;
    final commentCount = widget.item['comment_count'] as int;
    final username = widget.item['username'] as String;
    final newsTitle = widget.item['news_title'] as String;
    final newsThumbnail = widget.item['news_thumbnail'] as String;
    final newsSource = widget.item['news_source'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC5D1DF), width: 1.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE5EDF7), child: Icon(Icons.person, color: Color(0xFF8799AF))),
              const SizedBox(width: 13),
              Expanded(child: Text('@$username', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('このニュースを読みました👇', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF52657A))),
          const SizedBox(height: 10),
          
          // 👇 追加：どのニュースを読んだかわかるプレビューカード
          InkWell(
            onTap: _openNews,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8FAFD),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    child: newsThumbnail.isNotEmpty
                        ? Image.network(newsThumbnail, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 80, height: 80, child: Icon(Icons.image)))
                        : const SizedBox(width: 80, height: 80, child: Icon(Icons.image, color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(newsTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
                          const SizedBox(height: 6),
                          Text(newsSource, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, size: 22, color: isLiked ? Colors.blue : const Color(0xFF52657A)), 
                    const SizedBox(width: 6), 
                    Text('いいね ($likeCount)', style: TextStyle(color: isLiked ? Colors.blue : const Color(0xFF52657A), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              InkWell(
                onTap: _showCommentSheet, // 👈 コメントシートを開く！
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 21, color: Color(0xFF52657A)), 
                    const SizedBox(width: 6), 
                    Text('コメント ($commentCount)', style: const TextStyle(color: Color(0xFF52657A), fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 追加: コメントを入力・表示するボトムシート
// ==========================================
class _CommentSheet extends StatefulWidget {
  final String historyId;
  const _CommentSheet({required this.historyId});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _commentController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final client = Supabase.instance.client;
      // コメント一覧を取得
      final data = await client.from('news_comments').select('user_id, comment, created_at').eq('user_read_news_id', widget.historyId).order('created_at', ascending: true);
      
      List<Map<String, dynamic>> enriched = [];
      for (var c in data) {
        final p = await client.from('profiles').select('username').eq('id', c['user_id']).maybeSingle();
        enriched.add({
          'username': p?['username'] ?? 'ユーザー',
          'comment': c['comment'],
        });
      }
      if (mounted) setState(() { _comments = enriched; _isLoading = false; });
    } catch (e) {
      debugPrint('コメント取得エラー: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear(); // 送信したら入力欄を空にする

    try {
      final client = Supabase.instance.client;
      final currentUserId = TestSession.currentUserId ?? client.auth.currentUser?.id;
      
      await client.from('news_comments').insert({
        'user_read_news_id': widget.historyId,
        'user_id': currentUserId,
        'comment': text,
      });
      
      _loadComments(); // コメントを再読み込み
    } catch (e) {
      debugPrint('コメント送信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // キーボードの高さ分だけ下を浮かせる設定
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: 400, // シートの高さ
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), borderRadius: BorderRadius.all(Radius.circular(10))))),
            const SizedBox(height: 16),
            const Text('コメント', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // コメント一覧
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('まだコメントはありません', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE5EDF7), child: Icon(Icons.person, size: 18, color: Color(0xFF8799AF))),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('@${c['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(c['comment'], style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            
            // コメント入力欄
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'コメントを追加...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blue)),
                    ),
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFD7DFE9)))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(icon: Icons.home_outlined, label: 'ホーム', active: true),
              _NavItem(icon: Icons.location_on_outlined, label: '地図', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorldMapPage()))),
              _NavItem(icon: Icons.person_outline, label: 'マイページ', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()))),
              _NavItem(icon: Icons.settings_outlined, label: '設定', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsPage()))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback? onTap;
  const _NavItem({required this.icon, required this.label, this.active = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF111827) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 27), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500))]),
    );
  }
}

// ==========================================
// 追加: 自分の今日のニュースと、そこに付いたいいね・コメントを表示するカード
// ==========================================
class _MyTodayNewsFeedCard extends StatefulWidget {
  const _MyTodayNewsFeedCard();

  @override
  State<_MyTodayNewsFeedCard> createState() => _MyTodayNewsFeedCardState();
}

class _MyTodayNewsFeedCardState extends State<_MyTodayNewsFeedCard> {
  bool _isLoading = true;
  Map<String, dynamic> _myHistoryData = {};

  @override
  void initState() {
    super.initState();
    _loadMyLatestHistory();
  }

  Future<void> _loadMyLatestHistory() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = TestSession.currentUserId ?? client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 1. 自分が今日読んだ最新の履歴を1件取得
      final response = await client
          .from('user_read_news')
          .select('id, news_url, created_at')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final history = response[0];
      final historyId = history['id'];
      final newsUrl = history['news_url'];

      // 2. ニュース詳細を取得
      final newsData = await client.from('news').select('title, thumbnail_url, source').eq('url', newsUrl).limit(1);
      final newsTitle = newsData.isNotEmpty ? newsData[0]['title']?.toString() ?? 'タイトル不明' : 'タイトル不明';
      final newsThumbnail = newsData.isNotEmpty ? newsData[0]['thumbnail_url']?.toString() ?? '' : '';
      final newsSource = newsData.isNotEmpty ? newsData[0]['source']?.toString() ?? 'ニュースサイト' : 'ニュースサイト';

      // 3. 自分宛てのいいね・コメント数を取得
      final likes = await client.from('news_likes').select('user_id').eq('user_read_news_id', historyId);
      final comments = await client.from('news_comments').select('id').eq('user_read_news_id', historyId);

      if (mounted) {
        setState(() {
          _myHistoryData = {
            'history_id': historyId,
            'news_url': newsUrl,
            'news_title': newsTitle,
            'news_thumbnail': newsThumbnail,
            'news_source': newsSource,
            'like_count': likes.length,
            'comment_count': comments.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('マイ履歴取得エラー: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCommentSheet() {
    final historyId = _myHistoryData['history_id']?.toString();
    debugPrint('コメントボタンが押されました。historyId: $historyId'); // 👈 ターミナルに文字が出るか確認用

    if (historyId == null || historyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニュース履歴のIDが見つかりません')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CommentSheet(historyId: historyId),
    ).then((_) => _loadMyLatestHistory());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myHistoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    final likeCount = _myHistoryData['like_count'] as int;
    final commentCount = _myHistoryData['comment_count'] as int;
    final newsTitle = _myHistoryData['news_title'] as String;
    final newsThumbnail = _myHistoryData['news_thumbnail'] as String;
    final newsSource = _myHistoryData['news_source'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5D1DF), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: Color(0xFFE5EDF7), child: Icon(Icons.person, color: Color(0xFF8799AF))),
              SizedBox(width: 13),
              Expanded(child: Text('あなた', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('あなたが今日読んだニュース👇', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF52657A))),
          const SizedBox(height: 10),
          
          // ニュースプレビュー
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFD),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                  child: newsThumbnail.isNotEmpty
                      ? Image.network(newsThumbnail, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 80, height: 80, child: Icon(Icons.image)))
                      : const SizedBox(width: 80, height: 80, child: Icon(Icons.image, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(newsTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(newsSource, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, size: 22, color: Color(0xFF52657A)),
                  const SizedBox(width: 6),
                  Text('いいね ($likeCount)', style: const TextStyle(color: Color(0xFF52657A), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 22),
              InkWell(
                onTap: _showCommentSheet, // 👈 自分宛てのコメントを確認・返信できる！
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 21, color: Color(0xFF52657A)),
                    const SizedBox(width: 6),
                    Text('コメント ($commentCount)', style: const TextStyle(color: Color(0xFF52657A), fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}