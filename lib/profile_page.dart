import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2; // 「マイページ」を選択状態にする

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
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5); // 背景色
    const textColor = Color(0xFF334155);       // テキスト色

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ヘッダー（タイトル ＋ 右上アイコン）
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
                      icon: const Icon(Icons.person_add_outlined, color: textColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: textColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // プロフィールアイコン
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ユーザー名
            const Center(
              child: Text(
                '@takumi_news',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // フォロー / フォロワー数
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('128', 'フォロー中'),
                const SizedBox(width: 36),
                _buildStatItem('256', 'フォロワー'),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(color: Color(0xFFCBD5E1), thickness: 1),
            const SizedBox(height: 12),

            // セクション見出し: 📌 Pins
            const Text(
              '📌 Pins',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // ピン留め記事カード一覧
            ..._pins.map((pin) => _buildPinCard(pin)),
          ],
        ),
      ),

      // 下部ナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFE4EBF5),
        selectedItemColor: const Color(0xFF334155),
        unselectedItemColor: const Color(0xFF94A3B8),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

  // フォロー/フォロワーの数字とラベル
  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // Pinsのカードウィジェット
  Widget _buildPinCard(Map<String, String> pin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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