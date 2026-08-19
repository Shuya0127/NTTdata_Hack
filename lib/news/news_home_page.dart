import 'package:flutter/material.dart';

class NewsHomePage extends StatelessWidget {
  const NewsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      // 下部ナビゲーション
      bottomNavigationBar: const _BottomNavigation(),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // ヘッダー
              // =========================
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

              // =========================
              // 今日のニュース
              // =========================
              Container(
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
                    // 国・時刻
                    const Row(
                      children: [
                        Text(
                          '🇫🇷',
                          style: TextStyle(fontSize: 24),
                        ),

                        SizedBox(width: 8),

                        Text(
                          'フランス',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(width: 8),

                        Text(
                          '配信時刻 14:05',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ニュース画像（今はダミー）
                    Container(
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
                    ),

                    const SizedBox(height: 18),

                    // ニュースタイトル
                    const Center(
                      child: Text(
                        'フランス政府が新たな政策を発表',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // タップして読む
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ニュースURLとの連携は次の段階で実装します',
                              ),
                            ),
                          );
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
              ),

              const SizedBox(height: 28),

              // =========================
              // フレンドのフィード
              // =========================
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

              // =========================
              // ロックされたフィード
              // =========================
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
// フレンドの投稿
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE5EDF7),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF8799AF),
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
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
                      style: TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                '🌐',
                style: TextStyle(fontSize: 25),
              ),

              const SizedBox(width: 5),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '国名',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                  Text(
                    'フランス',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 投稿内容
          const Text(
            'フランスで新たな気候変動対策が発表。',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // いいね・コメント
          const Row(
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
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