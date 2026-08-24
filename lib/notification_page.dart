import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_friend.dart';
import 'notification_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<_NotificationSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<_NotificationSettings> _loadSettings() async {
    final followRequestsEnabled =
        await NotificationPreferences.followRequestsEnabled();
    final newsUpdatesEnabled =
        await NotificationPreferences.newsUpdatesEnabled();
    final pendingRequests = followRequestsEnabled
        ? await _loadPendingRequestsCount()
        : 0;
    return _NotificationSettings(
      followRequestsEnabled: followRequestsEnabled,
      newsUpdatesEnabled: newsUpdatesEnabled,
      pendingRequests: pendingRequests,
    );
  }

  Future<int> _loadPendingRequestsCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    final rows = await Supabase.instance.client
        .from('friendships')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('status', 'pending');
    return List<dynamic>.from(rows).length;
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFD);
    const text = Color(0xFF111827);
    const subtext = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        centerTitle: true,
        title: const Text(
          '通知',
          style: TextStyle(fontWeight: FontWeight.bold, color: text),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FutureBuilder<_NotificationSettings>(
            future: _settingsFuture,
            builder: (context, snapshot) {
              final settings = snapshot.data;
              final count = settings?.pendingRequests ?? 0;
              final followRequestsEnabled =
                  settings?.followRequestsEnabled ?? true;
              return _NotificationTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'フレンド申請',
                message: !followRequestsEnabled
                    ? 'フォロー申請通知はオフです'
                    : count == 0
                    ? '受信したフレンド申請はありません'
                    : '$count件のフレンド申請があります',
                highlighted: count > 0,
                onTap: followRequestsEnabled
                    ? () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FriendRequestsPage(),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {
                          _settingsFuture = _loadSettings();
                        });
                      }
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<_NotificationSettings>(
            future: _settingsFuture,
            builder: (context, snapshot) {
              final newsUpdatesEnabled =
                  snapshot.data?.newsUpdatesEnabled ?? true;
              return _NotificationTile(
                icon: Icons.newspaper_outlined,
                title: 'ニュース更新',
                message: newsUpdatesEnabled
                    ? '最新ニュースをホームで確認できます'
                    : 'ニュース更新通知はオフです',
                onTap: null,
              );
            },
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              '通知を受け取るには、設定から通知を許可してください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: subtext),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettings {
  const _NotificationSettings({
    required this.followRequestsEnabled,
    required this.newsUpdatesEnabled,
    required this.pendingRequests,
  });

  final bool followRequestsEnabled;
  final bool newsUpdatesEnabled;
  final int pendingRequests;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: highlighted
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFEFF3F8),
                child: Icon(icon, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
