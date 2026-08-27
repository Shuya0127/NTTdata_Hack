import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_page.dart';
import 'notification_preferences.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.iconSize = 28});

  final double iconSize;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _countFuture = _loadUnreadCount();
  }

  Future<int> _loadUnreadCount() async {
    if (!await NotificationPreferences.followRequestsEnabled()) return 0;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    final rows = await Supabase.instance.client
        .from('friendships')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('status', 'pending');
    return List<dynamic>.from(rows).length;
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationPage()));
    if (mounted) setState(() => _countFuture = _loadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _countFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: _openNotifications,
              tooltip: '通知',
              icon: Icon(
                Icons.notifications_none_rounded,
                size: widget.iconSize,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
