import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_friend.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<int> _pendingRequestsFuture;

  @override
  void initState() {
    super.initState();
    _pendingRequestsFuture = _loadPendingRequestsCount();
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
          FutureBuilder<int>(
            future: _pendingRequestsFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _NotificationTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'フレンド申請',
                message: count == 0
                    ? '受信したフレンド申請はありません'
                    : '$count件のフレンド申請があります',
                highlighted: count > 0,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FriendRequestsPage(),
                    ),
                  );
                  if (!mounted) return;
                  setState(() {
                    _pendingRequestsFuture = _loadPendingRequestsCount();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),
          const _NotificationTile(
            icon: Icons.newspaper_outlined,
            title: 'ニュース更新',
            message: '最新ニュースをホームで確認できます',
            onTap: null,
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
