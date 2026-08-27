import 'package:shared_preferences/shared_preferences.dart';

/// 端末ごとの通知表示設定を管理する。
class NotificationPreferences {
  static const _newsUpdatesKey = 'news_updates_notifications_enabled';
  static const _followRequestsKey = 'follow_request_notifications_enabled';
  static const _likesCommentsKey = 'likes_comments_notifications_enabled';
  static const _lastSeenKey = 'notifications_last_seen_at';

  static Future<bool> newsUpdatesEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_newsUpdatesKey) ?? true;
  }

  static Future<bool> followRequestsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_followRequestsKey) ?? true;
  }

  static Future<bool> likesCommentsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_likesCommentsKey) ?? true;
  }

  static Future<void> setNewsUpdatesEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_newsUpdatesKey, enabled);
  }

  static Future<void> setFollowRequestsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_followRequestsKey, enabled);
  }

  static Future<void> setLikesCommentsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_likesCommentsKey, enabled);
  }

  /// 通知画面を最後に開いた日時。これより後に届いたものだけを「未確認」として扱う。
  static Future<DateTime> lastSeenAt() async {
    final preferences = await SharedPreferences.getInstance();
    final iso = preferences.getString(_lastSeenKey);
    if (iso == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// 通知画面を開いたタイミングで呼び出し、「今すぐ確認した」ことを記録する。
  static Future<void> markNotificationsSeenNow() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSeenKey, DateTime.now().toUtc().toIso8601String());
  }
}
