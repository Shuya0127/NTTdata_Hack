import 'package:flutter/material.dart';

import 'notification_counts.dart';
import 'notification_page.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.iconSize = 28});

  final double iconSize;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late Future<bool> _hasUnseenFuture;

  @override
  void initState() {
    super.initState();
    _hasUnseenFuture = NotificationCounts.hasUnseen();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationPage()));
    // NotificationPage側で「確認済み」を記録しているので、戻ってきたら再判定する。
    if (mounted) {
      setState(() {
        _hasUnseenFuture = NotificationCounts.hasUnseen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasUnseenFuture,
      builder: (context, snapshot) {
        final hasUnseen = snapshot.data ?? false;
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
            if (hasUnseen)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
