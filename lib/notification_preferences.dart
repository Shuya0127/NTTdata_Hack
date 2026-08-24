import 'package:shared_preferences/shared_preferences.dart';

/// 端末ごとの通知表示設定を管理する。
class NotificationPreferences {
  static const _newsUpdatesKey = 'news_updates_notifications_enabled';
  static const _followRequestsKey = 'follow_request_notifications_enabled';

  static Future<bool> newsUpdatesEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_newsUpdatesKey) ?? true;
  }

  static Future<bool> followRequestsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_followRequestsKey) ?? true;
  }

  static Future<void> setNewsUpdatesEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_newsUpdatesKey, enabled);
  }

  static Future<void> setFollowRequestsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_followRequestsKey, enabled);
  }
}
