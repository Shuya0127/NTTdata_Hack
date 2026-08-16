import 'package:flutter/material.dart';

class NewsHomePage extends StatelessWidget {
  const NewsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 上部
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: const Text(
                  'DAILY NEWS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // カテゴリ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '災害・気象',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ニュースタイトル
                    const Text(
                      '【千葉豪雨】死者10人に\n夜にかけ雨のおそれ\n土砂災害に注意を',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 出典・日付
                    Row(
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        const Text(
                          'NHK NEWS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          '2026年8月16日',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // メイン画像の代わり
                    Container(
                      width: double.infinity,
                      height: 210,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water,
                            size: 65,
                            color: Colors.blueGrey.shade400,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            '千葉県で記録的な豪雨',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 概要見出し
                    const Text(
                      'ニュース概要',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 概要
                    const Text(
                      '千葉県では記録的な豪雨によって各地で大きな被害が発生しています。'
                      '県内では新たに死亡が確認された人を含め、豪雨による死者は10人となりました。'
                      'また、現在も行方が分かっていない人がおり、捜索が続けられています。',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      '住宅への浸水などの被害も広い範囲で確認されています。'
                      '雨が弱まった地域でも地盤が緩んでいる可能性があるため、'
                      '引き続き土砂災害などへの警戒が必要です。',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ポイント
                    const Text(
                      'このニュースのポイント',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _pointCard(
                      icon: Icons.people_alt_outlined,
                      title: '人的被害',
                      text: '千葉県内で死者10人。行方不明者の捜索も続いています。',
                    ),

                    const SizedBox(height: 12),

                    _pointCard(
                      icon: Icons.home_outlined,
                      title: '住宅被害',
                      text: '床上・床下浸水など、多数の住宅で被害が確認されています。',
                    ),

                    const SizedBox(height: 12),

                    _pointCard(
                      icon: Icons.warning_amber_rounded,
                      title: '今後も注意',
                      text: '雨や土砂災害への警戒を続ける必要があります。',
                    ),

                    const SizedBox(height: 35),

                    const Divider(),

                    const SizedBox(height: 20),

                    const Text(
                      '出典',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'NHK NEWS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '※この記事はプロトタイプ表示用に要約しています。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pointCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 27,
            color: Colors.blueGrey,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey.shade700,
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