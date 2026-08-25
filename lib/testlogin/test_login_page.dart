import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../news/news_home_page.dart';

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

  Future<void> _loginAsUser() async {
    final input = _uuidController.text.trim().replaceFirst('@', '');
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('IDを入力してください')));
      return;
    }

    try {
      final profile = await _findProfile(input);
      if (profile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('該当するプロフィールが見つかりません')));
        return;
      }

      // 画面間では必ず profiles.id のUUIDを使う。
      TestSession.currentUserId = profile['id'].toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_news');
      await prefs.remove('cached_news_time');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NewsHomePage()),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('プロフィール取得エラー: ${error.message}')));
    }
  }

  Future<Map<String, dynamic>?> _findProfile(String input) {
    final profiles = Supabase.instance.client.from('profiles');
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (uuidPattern.hasMatch(input)) {
      return profiles.select('id').eq('id', input).maybeSingle();
    }

    return profiles
        .select('id')
        .or('user_id.eq.$input,username.eq.$input')
        .maybeSingle();
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
              'テストするユーザーのUUID・ユーザーID・ユーザー名を\n入力してください。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _uuidController,
              decoration: const InputDecoration(
                labelText: 'UUID / ユーザーID / ユーザー名',
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
