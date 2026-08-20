import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  late Future<Map<String, dynamic>?> _newsFuture;

  @override
  void initState() {
    super.initState();

    // 画面を開いたときにランダムなニュースを1件取得
    _newsFuture = _getRandomNews();
  }

  // ============================================================
  // Supabaseからニュースを複数取得し、
  // その中からランダムに1件選ぶ
  // ============================================================

  Future<Map<String, dynamic>?> _getRandomNews() async {
    try {
      // Supabaseからニュースを最大100件取得
      final data = await Supabase.instance.client
          .from('news')
          .select(
            'title, url, content, thumbnail_url, source, published_at, country',
          )
          .limit(100);

      debugPrint('Supabaseから取得したニュース数: ${data.length}');

      // ニュースが0件の場合
      if (data.isEmpty) {
        debugPrint('newsテーブルにデータがありません');
        return null;
      }

      // 0 ～ ニュース件数-1 の中からランダムな番号を作る
      final random = Random();
      final randomIndex = random.nextInt(data.length);

      // ランダムに選ばれたニュース
      final randomNews =
          Map<String, dynamic>.from(data[randomIndex]);

      debugPrint('ランダムに選ばれたニュース: $randomNews');

      return randomNews;
    } catch (e) {
      debugPrint('Supabase取得エラー: $e');
      rethrow;
    }
  }

  // ============================================================
  // ニュースを再取得
  // ============================================================

  void _reloadNews() {
    setState(() {
      // 再読み込みするたびにランダムで選び直す
      _newsFuture = _getRandomNews();
    });
  }

  // ============================================================
  // ニュースURLを開く
  // ============================================================

  Future<void> _openNewsUrl(String url) async {
    if (url.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ニュースURLが登録されていません'),
        ),
      );

      return;
    }

    final Uri? newsUri = Uri.tryParse(url.trim());

    if (newsUri == null ||
        !(newsUri.scheme == 'http' || newsUri.scheme == 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ニュースURLが正しくありません'),
        ),
      );

      return;
    }

    try {
      final bool opened = await launchUrl(
        newsUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ニュースサイトを開けませんでした'),
          ),
        );
      }
    } catch (e) {
      debugPrint('URLを開く際のエラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ニュースサイトを開けませんでした: $e'),
        ),
      );
    }
  }

  // ============================================================
  // 国コードから表示用文字を作る
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
    // thumbnail_urlが空の場合
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

          // 画像読み込み中
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              color: const Color(0xFFE6ECF4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },

          // 画像取得失敗時
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            debugPrint('画像読み込みエラー: $error');

            return _buildImagePlaceholder();
          },
        ),
      ),
    );
  }

  // ============================================================
  // 画像がない場合のプレースホルダー
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
        child: Icon(
          Icons.image_outlined,
          size: 55,
          color: Color(0xFF52657A),
        ),
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

      // 下部ナビゲーション
      bottomNavigationBar: const _BottomNavigation(),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),

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
                    onPressed: () {},
                    icon: const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 27,
                    ),
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

              FutureBuilder<Map<String, dynamic>?>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  // ---------------------------------------------
                  // 読み込み中
                  // ---------------------------------------------

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
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
                              style: TextStyle(
                                color: Color(0xFF667085),
                              ),
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
                        border: Border.all(
                          color: Colors.red.shade300,
                        ),
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
                  // ニュースが存在しない
                  // ---------------------------------------------

                  if (news == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF9AAEC6),
                        ),
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
                  // Supabaseからニュース取得成功
                  // ---------------------------------------------

                  final String title =
                      news['title']?.toString() ??
                          'タイトルなし';

                  final String url =
                      news['url']?.toString() ?? '';

                  final String content =
                      news['content']?.toString() ?? '';

                  final String thumbnailUrl =
                      news['thumbnail_url']?.toString() ?? '';

                  final String source =
                      news['source']?.toString() ?? '';

                  final String country =
                      news['country']?.toString() ?? 'ANY';

                  debugPrint(
                    '表示するタイトル: $title',
                  );

                  debugPrint(
                    'ニュースURL: $url',
                  );

                  debugPrint(
                    '画像URL: $thumbnailUrl',
                  );

                  debugPrint(
                    'ニュース提供元: $source',
                  );

                  // ---------------------------------------------
                  // ニュースカード
                  // ---------------------------------------------

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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                                source.isNotEmpty
                                    ? source
                                    : '今日のニュース',
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
                        // ニュース画像
                        // ---------------------------------------

                        _buildNewsImage(
                          thumbnailUrl,
                        ),

                        const SizedBox(height: 20),

                        // ---------------------------------------
                        // ニュースタイトル
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

                        // ---------------------------------------
                        // ニュース本文
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
                        // ニュースサイトを開く
                        // ---------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              _openNewsUrl(url);
                            },
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(
                                    0xFF111827,
                                  ),
                              side: const BorderSide(
                                color:
                                    Color(0xFFC5D1DF),
                                width: 1.5,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child: const Text(
                              'タップして読む',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w700,
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
                      color: Colors.black.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 42,
                      color: Colors.black,
                    ),

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
        border: Border.all(
          color: const Color(0xFFC5D1DF),
          width: 1.3,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE5EDF7),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF8799AF),
                ),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                      style: TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '🌐',
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
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
        border: Border(
          top: BorderSide(
            color: Color(0xFFD7DFE9),
          ),
        ),
      ),
      child: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 9,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'ホーム',
                active: true,
              ),

              _NavItem(
                icon: Icons.location_on_outlined,
                label: '地図',
              ),

              _NavItem(
                icon: Icons.person_outline,
                label: 'マイページ',
              ),

              _NavItem(
                icon: Icons.settings_outlined,
                label: '設定',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 下部ナビゲーションの1項目
// ============================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF111827)
        : const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 27,
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}