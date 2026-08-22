import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'news/news_home_page.dart';
import 'profile_edit_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // スイッチの状態管理
  bool _pushNotification = true;
  bool _newsNotification = true;
  bool _followerNotification = false;

  // タブの選択インデックス（3: 設定）
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5); // 背景色
    const textColor = Color(0xFF334155); // テキスト色

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const SizedBox(height: 10),
            // ヘッダータイトル
            const Text(
              '設定',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),

            // セクション: アカウント
            _buildSectionHeader('アカウント'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildNavTile(
                title: 'プロフィール編集',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // セクション: 通知
            _buildSectionHeader('通知'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSwitchTile(
                title: 'プッシュ通知',
                value: _pushNotification,
                onChanged: (val) => setState(() => _pushNotification = val),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSwitchTile(
                title: 'ニュース更新通知',
                value: _newsNotification,
                onChanged: (val) => setState(() => _newsNotification = val),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSwitchTile(
                title: 'フォロワー通知',
                value: _followerNotification,
                onChanged: (val) => setState(() => _followerNotification = val),
              ),
            ]),
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NewsHomePage()),
            );
            return;
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            return;
          }

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
            icon: Icon(Icons.person_outline),
            label: 'マイページ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  // セクション見出し
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  // 角丸白背景のカード枠
  Widget _buildCardGroup(List<Widget> children) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  // 画面遷移用タイル（右矢印つき）
  Widget _buildNavTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  // スイッチ付きタイル
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: const Color(0xFF475569),
        onChanged: onChanged,
      ),
    );
  }
}
