import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 キャッシュ操作のために追加
import '../news/news_home_page.dart'; // ニュース画面のインポート

// ==========================================
// アプリ全体で使い回せる「テスト用ID保存箱」
// ==========================================
class TestSession {
  static String? currentUserId;
}

class TestLoginPage extends StatefulWidget {
  const TestLoginPage({super.key});

  @override
  State<TestLoginPage> createState() => _TestLoginPageState();
}

class _TestLoginPageState extends State<TestLoginPage> {
  final _uuidController = TextEditingController();

  // 👇 async を追加しています
  Future<void> _loginAsUser() async {
    final uuid = _uuidController.text.trim();
    if (uuid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('IDを入力してください')));
      return;
    }

    // ① ここで入力されたIDを「保存箱」に入れる！
    TestSession.currentUserId = uuid;

    // ② ニュースのキャッシュ（5分制限）を強制的にリセットする！
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_news');
    await prefs.remove('cached_news_time');

    if (!mounted) return;

    // ③ 強制的にニュース画面へ移動
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const NewsHomePage()));
  }

  @override
  void dispose() {
    _uuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開発テスト用ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'profilesテーブルから\nなりすましたいユーザーの「id (UUID)」を\n貼り付けてください。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _uuidController,
              decoration: const InputDecoration(
                labelText: 'id (例: 5fb1133b-...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loginAsUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('このIDで起動する'),
            ),
          ],
        ),
      ),
    );
  }
}
