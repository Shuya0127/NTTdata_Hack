import 'package:flutter/material.dart';

import 'notification_counts.dart';

/// 未読通知(フレンド申請・いいね・コメント)があるとき、
/// アイコンの右上に赤い点を表示する。マイページのタブアイコンなどで使用する。
class NotificationDotIcon extends StatefulWidget {
  const NotificationDotIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  State<NotificationDotIcon> createState() => _NotificationDotIconState();
}

class _NotificationDotIconState extends State<NotificationDotIcon> {
  late Future<bool> _hasUnseenFuture;

  @override
  void initState() {
    super.initState();
    _hasUnseenFuture = NotificationCounts.hasUnseen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasUnseenFuture,
      builder: (context, snapshot) {
        final hasUnread = snapshot.data ?? false;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(widget.icon, color: widget.color, size: widget.size),
            if (hasUnread)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
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
