import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _avatarUrl;
  String? _username;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, username')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _avatarUrl = profile?['avatar_url']?.toString();
        _username = profile?['username']?.toString();
      });
    } catch (e) {
      debugPrint('プロフィール情報取得エラー: $e');
    }
  }

  Future<void> _showUsernameEditDialog() async {
    final currentName = _username ?? '';
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ユーザー名変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(
              hintText: '新しいユーザー名を入力',
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('ユーザー名を入力してください')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(trimmed);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('ユーザー名を入力してください')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(trimmed);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _updateUsername(result);
  }

  Future<void> _updateUsername(String newUsername) async {
    final user = Supabase.instance.client.auth.currentUser;
    final trimmed = newUsername.trim();

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン状態を確認できませんでした')),
      );
      return;
    }

    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を入力してください')),
      );
      return;
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'username': trimmed})
          .eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _username = trimmed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を更新しました')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ユーザー名更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfileAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログイン状態を確認できませんでした')),
        );
      }
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _isUploading = true;
      });

      const bucket = 'profile-images';
      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = Supabase.instance.client.storage.from(bucket);

      await storage.uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = storage.getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _avatarUrl = publicUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイコンを更新しました')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('アイコン更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF334155);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        centerTitle: true,
        title: const Text(
          'プロフィール編集',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: ClipOval(
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                            _avatarUrl!,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 92,
                              height: 92,
                              child: Icon(
                                Icons.person,
                                size: 52,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 52,
                            color: Color(0xFF64748B),
                          ),
                  ),
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Color(0x66000000),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '変更したい項目を選択してください',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 28),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _EditOption(
                  icon: Icons.add_a_photo_outlined,
                  title: 'アイコン画像変更',
                  onTap: _isUploading ? null : _updateProfileAvatar,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _EditOption(
                  icon: Icons.person_outline,
                  title: 'ユーザー名変更',
                  onTap: _showUsernameEditDialog,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _EditOption(
                  icon: Icons.lock_outline,
                  title: 'パスワード変更',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOption extends StatelessWidget {
  const _EditOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF475569)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
