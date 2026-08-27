import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_preferences.dart';
import 'testlogin/test_login_page.dart';

/// アプリ全体の未読通知件数(フレンド申請 + いいね・コメント)をまとめて取得する。
/// マイページのバッジ表示・ベルアイコンなど、複数箇所から共通で利用する。
class NotificationCounts {
  /// 通知画面を最後に確認した時刻より後に届いた、未確認の通知があるかどうか。
  /// マイページのタブアイコンやベルアイコンの「赤い点」表示に使う。
  static Future<bool> hasUnseen() async {
    final lastSeen = await NotificationPreferences.lastSeenAt();
    final followRequestsEnabled =
        await NotificationPreferences.followRequestsEnabled();
    final likesCommentsEnabled =
        await NotificationPreferences.likesCommentsEnabled();

    if (followRequestsEnabled && await _hasNewPendingRequest(lastSeen)) {
      return true;
    }
    if (likesCommentsEnabled && await _hasNewReaction(lastSeen)) {
      return true;
    }
    return false;
  }

  static Future<bool> _hasNewPendingRequest(DateTime lastSeen) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final rows = await Supabase.instance.client
        .from('friendships')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('status', 'pending')
        .gt('created_at', lastSeen.toIso8601String())
        .limit(1);
    return List<dynamic>.from(rows).isNotEmpty;
  }

  static Future<bool> _hasNewReaction(DateTime lastSeen) async {
    final client = Supabase.instance.client;
    final currentUserId =
        TestSession.currentUserId ?? client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final myHistory = await client
        .from('user_read_news')
        .select('id')
        .eq('user_id', currentUserId);
    final historyIds = List<Map<String, dynamic>>.from(
      myHistory,
    ).map((history) => history['id'].toString()).toList();
    if (historyIds.isEmpty) return false;

    final lastSeenIso = lastSeen.toIso8601String();

    final likes = await client
        .from('news_likes')
        .select('id')
        .inFilter('user_read_news_id', historyIds)
        .neq('user_id', currentUserId)
        .gt('created_at', lastSeenIso)
        .limit(1);
    if (List<dynamic>.from(likes).isNotEmpty) return true;

    final comments = await client
        .from('news_comments')
        .select('id')
        .inFilter('user_read_news_id', historyIds)
        .neq('user_id', currentUserId)
        .gt('created_at', lastSeenIso)
        .limit(1);
    return List<dynamic>.from(comments).isNotEmpty;
  }

  static Future<int> totalUnread() async {
    final followRequestsEnabled =
        await NotificationPreferences.followRequestsEnabled();
    final likesCommentsEnabled =
        await NotificationPreferences.likesCommentsEnabled();

    final pending = followRequestsEnabled ? await _pendingRequestsCount() : 0;
    final reactions = likesCommentsEnabled ? await _likesCommentsCount() : 0;
    return pending + reactions;
  }

  static Future<int> _pendingRequestsCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    final rows = await Supabase.instance.client
        .from('friendships')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('status', 'pending');
    return List<dynamic>.from(rows).length;
  }

  static Future<int> _likesCommentsCount() async {
    final client = Supabase.instance.client;
    final currentUserId =
        TestSession.currentUserId ?? client.auth.currentUser?.id;
    if (currentUserId == null) return 0;

    final myHistory = await client
        .from('user_read_news')
        .select('id')
        .eq('user_id', currentUserId);
    final historyIds = List<Map<String, dynamic>>.from(
      myHistory,
    ).map((history) => history['id'].toString()).toList();
    if (historyIds.isEmpty) return 0;

    final likes = await client
        .from('news_likes')
        .select('id')
        .inFilter('user_read_news_id', historyIds)
        .neq('user_id', currentUserId);
    final comments = await client
        .from('news_comments')
        .select('id')
        .inFilter('user_read_news_id', historyIds)
        .neq('user_id', currentUserId);
    return List<dynamic>.from(likes).length +
        List<dynamic>.from(comments).length;
  }
}
