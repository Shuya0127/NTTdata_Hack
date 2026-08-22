import 'package:flutter/material.dart';

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

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
          const Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, size: 52, color: Color(0xFF64748B)),
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
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _EditOption(
                  icon: Icons.person_outline,
                  title: 'ユーザー名変更',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _EditOption(
                  icon: Icons.badge_outlined,
                  title: 'ユーザーID変更',
                  onTap: () {},
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
  final VoidCallback onTap;

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
