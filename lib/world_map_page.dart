import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';

class WorldMapPage extends StatefulWidget {
  const WorldMapPage({super.key});

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  // テスト用に最初から日本(jp)とアメリカ(us)をオレンジ色に設定
  final Map<String, Color> _visitedCountries = {
    'jp': const Color(0xFFFF9800), // 日本
    'us': const Color(0xFFFF9800), // アメリカ
  };
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5); // アプリ共通の背景色
    const textColor = Color(0xFF334155);       // テキスト色

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ワールドマップ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: textColor),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('マップを更新しました')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 獲得国数カウンターカード
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        '制覇した国',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_visitedCountries.length} カ国',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '🗺️ ニュースを読んで世界制覇！',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 世界地図表示エリア（拡大・縮小・スワイプ移動可能）
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 6.0,
                child: Center(
                  child: SimpleMap(
                    instructions: SMapWorld.instructions,
                    defaultColor: Colors.white, // 未読の国（白）
                    colors: _visitedCountries,   // 既読の国（オレンジ）
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ボトムナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: textColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: '地図'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'マイページ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}