import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account/account_creation_page.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  bool _saving = false;
  SupabaseClient get _supabase => Supabase.instance.client;
  User? get _user => _supabase.auth.currentUser;

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red : null,
        ),
      );

  Future<String?> _input(
    String title,
    String label,
    String initial, {
    bool obscure = false,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = _user;
    if (user == null) {
      _message('通常ログイン後にプロフィールを編集できます', error: true);
      return null;
    }
    return _supabase
        .from('profiles')
        .select('username, user_id')
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) _message(success);
    } on AuthException catch (e) {
      if (mounted) _message(e.message, error: true);
    } on PostgrestException catch (e) {
      if (mounted) _message(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeUsername() async {
    final profile = await _loadProfile();
    final user = _user;
    if (profile == null || user == null) return;
    final name = await _input(
      'ユーザー名変更',
      'ユーザー名',
      profile['username']?.toString() ?? '',
    );
    if (name == null || name.isEmpty) return;
    await _save(
      () => _supabase
          .from('profiles')
          .update({'username': name})
          .eq('id', user.id),
      'ユーザー名を変更しました',
    );
  }

  Future<void> _changeUserId() async {
    final profile = await _loadProfile();
    final user = _user;
    if (profile == null || user == null) return;
    final id = await _input(
      'ユーザーID変更',
      '英小文字・数字・_（3〜30文字）',
      profile['user_id']?.toString() ?? '',
    );
    if (id == null || id == profile['user_id']) return;
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(id)) {
      _message('ユーザーIDは英小文字・数字・_ を使って3〜30文字で入力してください', error: true);
      return;
    }
    await _save(() async {
      await _supabase.auth.updateUser(
        UserAttributes(email: authEmailFromUserId(id)),
      );
      await _supabase
          .from('profiles')
          .update({'user_id': id})
          .eq('id', user.id);
    }, 'ユーザーIDを変更しました。確認メールが届く場合があります。');
  }

  Future<void> _changePassword() async {
    if (_user == null) {
      _message('通常ログイン後にパスワードを変更できます', error: true);
      return;
    }
    final password = await _input('パスワード変更', '8文字以上', '', obscure: true);
    if (password == null || password.isEmpty) return;
    if (password.length < 8) {
      _message('パスワードは8文字以上で入力してください', error: true);
      return;
    }
    await _save(
      () => _supabase.auth.updateUser(UserAttributes(password: password)),
      'パスワードを変更しました',
    );
  }

  Future<void> _changeAvatar() async {
    final user = _user;
    if (user == null) {
      _message('通常ログイン後に画像を変更できます', error: true);
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _save(() async {
      final name =
          'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            name,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': _supabase.storage
                .from('profile-images')
                .getPublicUrl(name),
          })
          .eq('id', user.id);
    }, 'プロフィール画像を変更しました');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE4EBF5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFE4EBF5),
      surfaceTintColor: const Color(0xFFE4EBF5),
      centerTitle: true,
      title: const Text('プロフィール編集'),
    ),
    body: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(radius: 46, child: Icon(Icons.person, size: 52)),
            const SizedBox(height: 12),
            const Center(child: Text('変更したい項目を選択してください')),
            const SizedBox(height: 28),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _Option(
                    Icons.add_a_photo_outlined,
                    'アイコン画像変更',
                    _changeAvatar,
                  ),
                  const Divider(height: 1),
                  _Option(Icons.person_outline, 'ユーザー名変更', _changeUsername),
                  const Divider(height: 1),
                  _Option(Icons.badge_outlined, 'ユーザーID変更', _changeUserId),
                  const Divider(height: 1),
                  _Option(Icons.lock_outline, 'パスワード変更', _changePassword),
                ],
              ),
            ),
          ],
        ),
        if (_saving)
          const ColoredBox(
            color: Color(0x33000000),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
