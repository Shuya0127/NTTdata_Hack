import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'news/news_home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;

  String _userId = '読み込み中...';
  String _username = '読み込み中...';
  bool _isLoadingProfile = true;

  // Pins のデータ
  final List<Map<String, String>> _pins = [
    {
      'title': 'AIが変える未来の働き方とは',
      'date': '2024/12/15',
      'imageUrl': 'https://picsum.photos/seed/ai/200',
    },
    {
      'title': '東京の隠れた名店グルメ特集',
      'date': '2024/12/10',
      'imageUrl': 'https://picsum.photos/seed/gourmet/200',
    },
    {
      'title': '宇宙開発の最新トレンド2025',
      'date': '2024/12/08',
      'imageUrl': 'https://picsum.photos/seed/space/200',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Supabaseからログイン中ユーザーの情報を取得
    _loadProfile();
  }

  // ============================================================
  // SupabaseからユーザーID・ユーザー名を取得
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;

      // 現在ログインしているユーザー
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _userId = '未ログイン';
          _username = 'ユーザー情報なし';
          _isLoadingProfile = false;
        });

        return;
      }

      // Supabase AuthのユーザーID
      final userId = user.id;

      // profilesテーブルからusernameを取得
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _userId = userId;
        _username =
            profile?['username']?.toString() ?? 'ユーザー名未設定';

        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('プロフィール取得エラー: $e');

      if (!mounted) return;

      setState(() {
        _userId = '取得エラー';
        _username = '取得エラー';
        _isLoadingProfile = false;
      });
    }
  }

  // ============================================================
  // 下部ナビゲーション
  // ============================================================

  void _onNavigationTapped(int index) {
    // ホーム
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const NewsHomePage(),
        ),
      );

      return;
    }

    // 地図
    if (index == 1) {
      setState(() {
        _selectedIndex = index;
      });

      return;
    }

    // マイページ
    if (index == 2) {
      setState(() {
        _selectedIndex = index;
      });

      return;
    }

    // 設定
    if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF334155);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          children: [
            // ======================================================
            // ヘッダー
            // ======================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ニュースBeReal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.person_add_outlined,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ======================================================
            // プロフィールアイコン
            // ======================================================

            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ======================================================
            // ユーザー情報
            // ======================================================

            if (_isLoadingProfile)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // ユーザー名
                    // ------------------------------------------------

                    const Text(
                      'ユーザー名',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '@$_username',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // ユーザーID
                    // ------------------------------------------------

                    const Text(
                      'ユーザーID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    SelectableText(
                      _userId,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            const Divider(
              color: Color(0xFFCBD5E1),
              thickness: 1,
            ),

            const SizedBox(height: 14),

            // ======================================================
            // Pins
            // ======================================================

            const Text(
              '📌 Pins',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            ..._pins.map(
              (pin) => _buildPinCard(pin),
            ),
          ],
        ),
      ),

      // ============================================================
      // 下部ナビゲーション
      // ============================================================

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: textColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        currentIndex: _selectedIndex,
        onTap: _onNavigationTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: '地図',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'マイページ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Pinsカード
  // ============================================================

  Widget _buildPinCard(
    Map<String, String> pin,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              pin['imageUrl']!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  pin['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Text(
                  pin['date']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}